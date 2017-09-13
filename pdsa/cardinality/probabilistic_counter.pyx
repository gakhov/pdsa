"""Probabilistic Counter (with sotchastic averaging).

Probabilistic Counting algorithm (Flajolet-Martin algorithm) was
proposed by Philippe Flajolet and G. Nigel Martin in 1985.

It's a hash-based probabilistic algorithm for counting the number of
distinct values in the presence of duplicates.

"""
import cython

from libc.math cimport round
from libc.stdint cimport uint8_t, uint16_t, uint32_t
from libc.stdlib cimport rand

from cpython.array cimport array
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit


cdef class ProbabilisticCounter:
    """Probabilistic Counter is a realisation of Flajolet-Martin algorithm.

    Example
    -------

    >>> from pdsa.cardinality.probabilsitic_counter import ProbabilisticCounter

    >>> pc = ProbabilisticCounter(256)
    >>> pc.add("hello")
    >>> pc.count()

    Note
    -----
        This implementation uses MurmurHash3 family of hash functions
        which yields a 32-bit hash value that implies the maximal length
        of the counter.

    Attributes
    ----------
    num_of_counters : :obj:`int`
        The number of simple counters (FM Sketches).

    with_small_cardinality_correction : :obj:`int`
        Flag if small cardinalities correction is required.

    Note
    -----
        The Algorithm has been developed for large cardinalities when
        ratio card()/num_of_counters > 10-20, therefore a special correction
        required if low cardinality cases has to be supported. In this implementation
        we use correction proposed by Scheuermann and Mauve (2007).

    """

    def __cinit__(self, const uint16_t num_of_counters,
                  const bint with_small_cardinality_correction = False):
        """Create probabilsistic counter using `num_of_counters` simple counters.

        Parameters
        ----------
        num_of_counters : :obj:`int`
            The number of simple counters (FM Sketches).

        with_small_cardinality_correction : :obj:`int`
            Flag if small cardinalities correction is required.

        Note
        ----
            The length of the probabilsitic counter is defined by the size of
            hashe values that produced by the family of hash functions
            (in our case it's 32 bits functions)

        Note
        ----
            Memory for the internal array is allocated by blocks
            (or chunks), therefore the final `length` of the counter
            can be rounded up to use whole allocated space efficiently.

        Raises
        ------
        ValueError
            If `num_of_counters` is 0 or negative.

        """
        if num_of_counters < 1:
            raise ValueError("At least one simple counter is required")

        self.num_of_counters = num_of_counters
        self.size = 32  # 32-bit hash functions produce 0..2^{32}-1 values
        self.with_small_cardinality_correction = with_small_cardinality_correction

        self._seed = <uint8_t>(rand())
        self._counter = BitVector(self.num_of_counters * self.size)

        self.length = len(self._counter)

        cdef size_t index
        for index in xrange(self.length):
            self._counter[index] = 0

    cdef uint32_t _hash(self, object key, uint32_t seed):
        return mmh3_x86_32bit(key, seed)

    cdef uint8_t _rank(self, uint32_t value):
        """Calculate rank that is the least significant bit position.

        Parameters
        ----------
        value : int
            The unsinged integer to find the LSB in binary representation.

        Returns
        -------
        :obj:`int`
            The LSB or, if value is zero, the `self.size`.

        """
        if value == 0:
            return self.size
        return (value & -value).bit_length() - 1

    def __dealloc__(self):
        pass

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef void add(self, object element) except *:
        """Index element into the counter.

        Parameters
        ----------
        element : obj
            The element to be indexed into the counter.

        Note
        ----
            The algorithm uses only 1 hash function, thus, to
            calculate the rank and counter index, it computes
            quotient and remainder from the hash value and use them
            respectively.

        """
        cdef uint16_t counter_index
        cdef uint32_t value
        cdef uint8_t value_index

        value, counter_index = divmod(
            self._hash(element, self._seed), self.num_of_counters)

        value_index = self._rank(value)
        if value_index < self.size:
            self._counter[counter_index * self.size + value_index] = 1

    cpdef size_t sizeof(self):
        """Size of the counter in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the counter.

        """
        return self._counter.sizeof()

    def __repr__(self):
        return "<ProbabilisticCounter (length: {}, num_of_counters: {})>".format(
            self.length,
            self.num_of_counters)

    def __len__(self):
        """Get length of the counter.

        Returns
        -------
        :obj:`int`
            The length of the counter.

        """
        return self.length

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef uint8_t _value_by_counter(self, uint16_t counter_index):
        """Get value from a single simple counter.

        The k-th bit in the counter correspods to the 0^{k}1 pattern
        that is used to estimate number of unique elements known
        to the counter. The leftmost 0 in the counter is an indicator
        of log_{2}(n) (in fact, with some correction factor).

        Parameters
        ----------
        counter_index : int
            The index of the counter.

        Returns
        -------
        :obj:`int`
            Relative index of the leftmost value 0 or, if all values
            are zero, the counter's size.

        Note
        ----
            Since all simple counters are stored in a single vector,
            we get counter by its index, and it is `self.size` bits long.
            In this case the returning value is the relative index
            inside that single counter.

        """
        cdef uint8_t value_index
        cdef bint found = False

        for value_index in xrange(self.size):
            if self._counter[counter_index * self.size + value_index] == 0:
                return value_index

        return self.size


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef size_t count(self):
        """Approximately count number of unique elements indexed into counter.

        Returns
        -------
        :obj:`int`
            The number of unique elements already in the counter.

        Note
        ----
            According to [1], the estimation of cardinality can be computed
            by averaging estimations from each counter and converting
            the result value N into expected number of unique elements by
            the formula:

                n ≈ 2^{N} / 0.77351

        Note
        -----
            If number of counters is less then 32, algorithm has a bias that
            can be corrected as proposed in [1].

        Note
        -----
            The Algorithm has been developed for large cardinalities when
            ratio card()/num_of_counters > 10-20, therefore a special correction
            required if low cardinality cases has to be supported. In this implementation
            we use correction proposed by Scheuermann and Mauve [2].

        References
        ----------
        [1] Flajolet, P., Martin, G.N.: Probabilistic Counting Algorithms
            for Data Base Applications. Journal of Computer and System Sciences.
            Vol. 31 (2), 182--209  (1985)
        [2] Flajolet, P., Martin, G.N.: Near-Optimal Compression of Probabilistic
            Counting Sketches for Networking Applications
            In Dial M-POMC 2007: Proceedings of the 4th ACM SIGACT-SIGOPS
            International Workshop on Foundation of Mobile Computing, 2007

        """
        if self._counter.count() == 0:
            return 0

        cdef float fm_magic_constant = 0.77351
        cdef float fm_correction_constant = 0.31
        cdef float sm_correction_constant = 1.75

        cdef uint16_t counter_index
        cdef uint16_t N = 0
        for counter_index in xrange(self.num_of_counters):
            N += self._value_by_counter(counter_index)

        cdef float small_number_of_counters_correction = 1.0
        if self.num_of_counters < 32:
            small_number_of_counters_correction = (
                1 - fm_correction_constant / self.num_of_counters)

        cdef float small_cardinality_correction = 0.0
        if self.with_small_cardinality_correction:
            small_cardinality_correction = pow(
                2,
                - sm_correction_constant * N / self.num_of_counters
            )

        return <size_t>round(
            self.num_of_counters *
            (
                pow(
                    2,
                    float(N) / self.num_of_counters
                )
                -
                small_cardinality_correction

            ) / (fm_magic_constant * small_number_of_counters_correction)
        )
