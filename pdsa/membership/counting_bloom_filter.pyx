"""
Counting Bloom Filter.

"""
import cython

from libc.math cimport ceil, log, round
from libc.stdint cimport uint32_t, uint8_t

from cpython.array cimport array
from cpython.ref cimport PyObject
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit

cdef class CountingBloomFilter:
    """Counting Bloom filter is a realisation of a probabilistic set.

    Bloom filter supports 3 operations:
        - add element into the set
        - test whether an element is a member of a set
        - test whether an element is not a member of a set
        - delete element from the set (probilistically correct)

    This implementation uses MurmurHash3 family of hash functions
    which yields a 32-bit hash value.
    """

    def __cinit__(self, const size_t length, const uint8_t num_of_hashes):
        """Initialize Bloom filter.

        Arguments:
        ----------
        length           - length of the Counting Bloom filter
        num_of_hashes    - number of hash functions used in the filter.

        """
        if length < 1:
            raise ValueError("Filter length can't be 0 or negative")
        if num_of_hashes < 1:
            raise ValueError("At least one ahsh function is required")

        self.num_of_hashes = num_of_hashes

        self._seeds = array('B', range(self.num_of_hashes))
        self._table = BitVector(length)

        self.length = len(self._table)

        self._counter = BitVectorCounter(self.length)

        cdef size_t index
        for index in xrange(self.length):
            self._table[index] = 0


    @classmethod
    def create_from_capacity(cls, const size_t capacity, const float error):
        """Initialize Counting Bloom filter from expected capacity and error rate.

        Arguments:
        ----------
        capacity    - expected number of elements that will be indexed into
                    the filter.
        error       - requested false positive rate (0 < error_rate < 1).
                    Based on this rate we calculate required number of hash
                    functions, but minimal number of hash function can't
                    be less then 1.
        """
        if capacity < 1:
            raise ValueError("Filter capacity can't be 0 or negative")

        if error <= 0 or error >= 1:
            raise ValueError("Error rate shell be in (0, 1)")

        cdef size_t length = - <size_t>(capacity * log(error) / (log(2) ** 2))
        cdef uint8_t num_of_hashes = - <uint8_t>(ceil(log(error) / log(2)))

        return cls(length, num_of_hashes)

    cdef uint32_t _hash(self, object key, uint8_t seed):
        # self.algorithm = "mmh3_x86_32bit"
        return mmh3_x86_32bit(key, seed)

    def __dealloc__(self):
        pass

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef void add(self, object element) except *:
        """Add a new element into the filter."""
        cdef uint8_t seed_index
        cdef uint8_t seed
        cdef size_t index
        for seed_index in range(self.num_of_hashes):
            seed = self._seeds[seed_index]
            index = self._hash(element, seed) % self.length
            self._table[index] = 1
            self._counter.increment(index)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef bint test(self, object element) except *:
        """Test whether element is in the filter.

        Due to the probabilistic nature of the Bloom filter,
        it has some false positive rate.
        """
        cdef uint8_t seed_index
        cdef uint8_t seed
        cdef size_t index
        for seed_index in range(self.num_of_hashes):
            seed = self._seeds[seed_index]
            index = self._hash(element, seed) % self.length
            if self._table[index] != 1:
                return False
        return True

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef bint remove(self, object element) except *:
        """Delete element from the filter.

        CountingBloomFilter uses limited 4-bits counters that
        freeze at maximal value (15), so the deletion
        is only probabilistically correct.
        """
        cdef uint8_t seed_index
        cdef uint8_t seed
        cdef array indices = array('Q', [0] * self.num_of_hashes)
        for seed_index in range(self.num_of_hashes):
            seed = self._seeds[seed_index]
            indices[seed_index] = self._hash(element, seed) % self.length
            
        cdef size_t index
        for index in indices:
            if self._table[index] != 1:
                return False

        for index in indices:
            self._counter.decrement(index)
            if self._counter[index] == 0:
               self._table[index] = 0
        return True

    cpdef size_t sizeof(self):
        return self._table.sizeof() + self._counter.sizeof()

    def __contains__(self, object element):
        return self.test(element)

    def __repr__(self):
        return "<CountingBloomFilter (length: {}, hashes: {})>".format(
            self.length,
            self.num_of_hashes
        )

    def __len__(self):
        return self.length

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef size_t count(self):
        """Approximate number of elements already in the filter.

        There is no reliable way to calculate exact number of elements
        in the filter, but there are methods to approximate such number.

        References
        ----------
        [1] S. J. Swamidass, P. Baldi
            Mathematical correction for fingerprint similarity measures
            to improve chemical retrieval.
            Journal of Chemical Information and Modeling, 47(3): 952-964, 2007.

        """
        cdef size_t num_of_bits = self._table.count()

        if num_of_bits < self.num_of_hashes:
            return 0

        if num_of_bits == self.num_of_hashes:
            return 1

        if num_of_bits == self.length:
            return self.length

        estimation = log(self.length - num_of_bits) - log(self.length)
        return <size_t>(- round(self.length * estimation / self.num_of_hashes))
