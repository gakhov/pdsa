"""HyperLogLog.

HyperLogLog algorithm was proposed by Philippe Flajolet, Éric Fusy,
Olivier Gandouet, and Frédéric Meunier in 2007.

It's a hash-based (32-bit hash function) probabilistic algorithm for
counting the number of distinct values in the presence of duplicates.

"""
import cython

from libc.math cimport log, round
from libc.stdint cimport uint8_t, uint16_t, uint32_t
from libc.stdlib cimport rand

from cpython.array cimport array

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit


cdef class HyperLogLog:
    """HyperLogLog is an implementation of the HyperLogLog algorithm.

    Example
    -------

    >>> from pdsa.cardinality.hyperloglog import HyperLogLog

    >>> hll = HyperLogLog(10)
    >>> hll.add("hello")
    >>> hll.count()

    Note
    -----
        This implementation uses MurmurHash3 family of hash functions
        which yields a 32-bit hash value. The maximal cardinality
        is about 2^32 items.

    Attributes
    ----------
    precision : :obj:`int`
        The number of bits from the hash value that is used for indexing.
    num_of_counters : :obj:`int`
        The number of simple counters (registers).

    Note
    -----
        The Algorithm has been developed for mid-range cardinalities and
        requires a correction (sub-algorithms) for small and large ranges
        due to non-linear errors.

    """

    UPPER_CORRECTION_THRESHOLD = 143165576 #  2^{32} / 30

    def __cinit__(self, const uint8_t precision):
        """Create HyperLogLog counter with `precision`.

        Parameters
        ----------
        precision : :obj:`int`
            The precision value that defines m = 2^precision simple counters.

        Note
        ----
            HyperLogLog algorithm uses a single 32-bit hash function which
            value is split for indexing and the hash computation.
            This implied contrains to the precision that has to be
            in the range 4...16

        Raises
        ------
        ValueError
            If `precision` is outside 4...16.

        """
        if precision < 4 or precision > 16:
            raise ValueError("Precision has to be in range 4...16")

        self.precision = precision
        self.num_of_counters = <uint32_t>1 << precision
        self.size = 32 - precision

        self._counter = array('L', range(self.num_of_counters))
        self._seed = <uint32_t>(rand())
        self._alpha = self._weight()

        cdef size_t index
        for index in xrange(self.num_of_counters):
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
            The LSB as the currect rank

        """
        assert value.bit_length() < self.size + 1
        return self.size - value.bit_length() + 1

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

        value, counter_index = divmod(
            self._hash(element, self._seed), self.num_of_counters)

        self._counter[counter_index] = max(
            self._counter[counter_index],
            self._rank(value))

    cpdef size_t sizeof(self):
        """Size of the counter in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the counter.

        """
        cdef uint8_t bytes_per_counter = 4  # 'L' unsigned long takes 4 bytes
        return bytes_per_counter * self.num_of_counters

    def __repr__(self):
        return "<HyperLogLog (length: {}, precision: {})>".format(
            self.num_of_counters,
            self.precision)

    def __len__(self):
        """Get the number of the simple counters (registers).

        Returns
        -------
        :obj:`int`
            The length of the counter.

        """
        return self.num_of_counters

    def debug(self):
        """Return hll for debug purposes."""
        return self._counter

    @cython.boundscheck(False)
    @cython.cdivision(True)
    cdef float _weight(self):
        """Compute weight for cardinality estimators based on the counters.

        Returns
        -------
        :obj:`float`
            The weight for bias correction in mid-range.

        """
        if self.num_of_counters < 16:
            return 0.673
        if self.num_of_counters < 32:
            return 0.697
        if self.num_of_counters < 64:
            return 0.709

        return (0.7213 * self.num_of_counters) / (self.num_of_counters + 1.079)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef size_t count(self):
        """Approximately count unique elements indexed by hyperloglog counter.

        Returns
        -------
        :obj:`int`
            The number of unique elements.

        References
        ----------
        [1] Flajolet, P., et al.: HyperLogLog: the analysis of a
            near-optimal cardinality estimation algorithm.
            Proceedings of the 2007 International Conference on Analysis of
            Algorithms, Juan les Pins, France – June 17-22, 2007, pp. 127–146.

        """
        cdef float R = 0
        cdef uint16_t counter_index
        cdef bint all_zero = 1
        for counter_index in xrange(self.num_of_counters):
            if self._counter[counter_index] > 0:
                all_zero = 0

            R += 1.0 / float(<uint32_t>1 << self._counter[counter_index])

        if all_zero:
            return 0

        cdef size_t n = <size_t>round(
            self._alpha * self.num_of_counters * self.num_of_counters / R
        )

        cdef uint16_t Z = 0
        if n < 2.5 * self.num_of_counters:
            for counter_index in xrange(self.num_of_counters):
                if self._counter[counter_index] == 0:
                    Z += 1

            if Z > 0:
                return <size_t>round(
                    self.num_of_counters * (log(self.num_of_counters) - log(Z))
                )
        elif n > self.UPPER_CORRECTION_THRESHOLD:
            n = <size_t>round(-4294967296 * log(1 - n / 4294967296.0))

        return n
