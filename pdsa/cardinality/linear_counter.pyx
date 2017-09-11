"""Linear Counter.

A Linear-Time probabilistic counting algorithm, or Linear Counting algorithm,
was proposed by Kyu-Young Whang at al. in 1990.

It's a hash-based probabilistic algorithm for counting the number of
distinct values in the presence of duplicates.

The algorithm has O(N) time complexity, where N is the total number of elements,
including duplicates.

"""
import cython

from libc.math cimport log, round
from libc.stdint cimport uint32_t, uint8_t
from libc.stdlib cimport rand

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit


cdef class LinearCounter:
    """Linear Counter is a realisation of Linear-Time probabilistic counting.

    Example
    -------

    >>> from pdsa.cardinality.linear_counter import LinearCounter

    >>> lc = LinearCounter(1000000)
    >>> lc.add("hello")
    >>> lc.count()


    Note
    -----
        This implementation uses MurmurHash3 family of hash functions
        which yields a 32-bit hash value that implies the maximal length
        of the counter.

    Attributes
    ----------
    length : :obj:`int`
        The length of the counter.

    """

    def __cinit__(self, const size_t length):
        """Create counter from its length.

        Parameters
        ----------
        length : :obj:`int`
            The length of the counter.

        Note
        ----
            Memory for the internal array is allocated by blocks
            (or chunks), therefore the final `length` of the counter
            can be rounded up to use whole allocated space efficiently.

        Raises
        ------
        ValueError
            If `length` is 0 or negative.

        """
        if length < 1:
            raise ValueError("Counter length can't be 0 or negative")

        self._seed = <uint8_t>(rand())
        self._counter = BitVector(length)

        self.length = len(self._counter)

        cdef size_t index
        for index in xrange(self.length):
            self._counter[index] = 0


    cdef uint32_t _hash(self, object key, uint8_t seed):
        # self.algorithm = "mmh3_x86_32bit"
        return mmh3_x86_32bit(key, seed)

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

        """
        cdef size_t index
        index = self._hash(element, self._seed) % self.length
        self._counter[index] = 1

    cpdef size_t sizeof(self):
        """Size of the counter in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the counter.

        """
        return self._counter.sizeof()

    def __repr__(self):
        return "<LinearCounter (length: {})>".format(self.length)

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
    @cython.cdivision(True)
    cpdef size_t count(self):
        """Approximately count number of unique elements indexed into counter.

        Returns
        -------
        :obj:`int`
            The number of unique elements already in the counter.

        Note
        ----
            According to [1], the estimation of cardinality can be done by:

                n ≈ –length * ln V,

            where V - the fraction of empty bits in the counter.

        References
        ----------
        [1] Whang, K.-Y., Vander-Zanden B.T., Taylor H.M.: A Linear-Time Probabilistic
            Counting Algorithm for Database Applications.
            Journal ACM Transactions on Database Systems.
            Vol. 15 (2), 208--229  (1990)

        """
        cdef size_t num_of_bits = self._counter.count()

        if num_of_bits == 0:
            return 0

        if num_of_bits == 1:
            return 1

        if num_of_bits == self.length:
            return self.length

        cdef float estimation = log(self.length - num_of_bits) - log(self.length)
        return <size_t>(self.length * (-estimation))
