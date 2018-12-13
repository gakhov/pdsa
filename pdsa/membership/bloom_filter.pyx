"""
Bloom Filter.

Bloom filter is a space-efficient probabilistic data structure
that supports membership queries. It offers a compact probabilistic
way to represent a set that can result in hard collisions (false positives),
but never false negatives.

The classical variant of the filter was proposed by Burton Howard Bloom in 1970.

References
----------
[1] Burton H. Bloom
    Space/Time Trade-offs in Hash Coding with Allowable Errors.
    Communications of the ACM, Volume 13 / Number 7 / July, 1970
    http://dmod.eu/deca/ft_gateway.cfm.pdf
[2] A. Broder, M. Mitzenmacher
    Network Applications of Bloom Filters: A Survey.
    Internet Mathematics Vol. 1, No. 4: 485-509
    https://www.eecs.harvard.edu/~michaelm/postscripts/im2005b.pdf
[3] S. Tarkoma, C. E. Rothenberg, E. Lagerspetz
    Theory and Practice of Bloom Filters for Distributed Systems.
    http://www.dca.fee.unicamp.br/~chesteve/pubs/bloom-filter-ieee-survey-preprint.pdf
"""
import cython

from libc.math cimport ceil, log, round
from libc.stdint cimport uint32_t, uint8_t

from cpython.array cimport array

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit

cdef class BloomFilter:
    """Bloom filter is a realisation of a probabilistic set.

    Bloom filter supports 3 operations:
        - add element into the set
        - test whether an element is a member of a set
        - test whether an element is not a member of a set.

    Example
    -------

    >>> from pdsa.membership.bloom_filter import BloomFilter

    >>> bf = BloomFilter(10000, 5)
    >>> bf.add("hello")
    >>> bf.test("hello")


    Note
    -----
        This implementation uses MurmurHash3 family of hash functions
        which yields a 32-bit hash value.

    Attributes
    ----------
    num_of_hashes : :obj:`int`
        The number of hash functions.
    length : :obj:`int`
        The length of the filter.

    """

    def __cinit__(self, const size_t length, const uint8_t num_of_hashes):
        """Create filter from its length and number of hash functions.

        Parameters
        ----------
        length : :obj:`int`
            The length of the filter
        num_of_hashes : :obj:`int`
            The number of hash functions used in the filter.

        Note
        ----
            Memory for the internal array is allocated by blocks
            (or chunks), therefore the final `length` of the filter
            can be bigger to use whole allocated space efficiently.

        Raises
        ------
        ValueError
            If `length` is 0 or negative.
        ValueError
            If number of hash functions is less than 1.

        """
        if length < 1:
            raise ValueError("Filter length can't be 0 or negative")
        if num_of_hashes < 1:
            raise ValueError("At least one hash function is required")

        self.num_of_hashes = num_of_hashes

        self._seeds = array('B', range(self.num_of_hashes))
        self._table = BitVector(length)

        self.length = len(self._table)

        cdef size_t index
        for index in xrange(self.length):
            self._table[index] = 0


    @classmethod
    def create_from_capacity(cls, const size_t capacity, const float error):
        """Create filter from expected capacity and error probability.

        Parameters
        ----------
        capacity : :obj:`int`
            Expected number of unique elements to be stored.
        error : float
            The false positive probability (0 < error < 1).

        Note
        ----
            The required length and number of required hash functions is
            calculated to support requested capacity and error probability.

        Raises
        ------
        ValueError
            If `capacity` is 0 or negative.
        ValueError
            If `error` not in range (0, 1).

        """
        if capacity < 1:
            raise ValueError("Filter capacity can't be 0 or negative")

        if error <= 0 or error >= 1:
            raise ValueError("Error rate shell be in (0, 1)")

        cdef size_t length = - <size_t>(capacity * log(error) / (log(2) ** 2))
        cdef uint8_t num_of_hashes = - <uint8_t>(ceil(log(error) / log(2)))

        return cls(length, max(1, num_of_hashes))

    cdef uint32_t _hash(self, object key, uint8_t seed):
        # self.algorithm = "mmh3_x86_32bit"
        return mmh3_x86_32bit(key, seed)

    def __dealloc__(self):
        pass

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef void add(self, object element) except *:
        """Add element into the filter.

        Parameters
        ----------
        element : obj
            The element to be added into the filter.

        """
        cdef uint8_t seed_index
        cdef uint8_t seed
        cdef size_t index
        for seed_index in range(self.num_of_hashes):
            seed = self._seeds[seed_index]
            index = self._hash(element, seed) % self.length
            self._table[index] = 1

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef bint test(self, object element) except *:
        """Test if element is in the filter.

        Parameters
        ----------
        element : obj
            The element to lookup.

        Returns
        -------
        bool
            True if the element may exists, False otherwise.

        Note
        ----
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

    cpdef size_t sizeof(self):
        """Size of the filter in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the filter.

        """
        return self._table.sizeof()

    def __contains__(self, object element):
        return self.test(element)

    def __repr__(self):
        return "<BloomFilter (length: {}, hashes: {})>".format(
            self.length,
            self.num_of_hashes
        )

    def __len__(self):
        """Get length of the filter.

        Returns
        -------
        :obj:`int`
            The length of the filter.

        """
        return self.length

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef size_t count(self):
        """Approximately count number of unique elements in the filter.

        Returns
        -------
        :obj:`int`
            The number of unique elements already in the filter.

        Note
        ----
            There is no reliable way to calculate exact number of elements
            in the filter, but there are methods [1] to approximate such number.
            This is an analog of the Linear Counting algorithm.

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
            return <size_t>(round(self.length / self.num_of_hashes))

        cdef float estimation = log(self.length - num_of_bits) - log(self.length)
        return <size_t>(round(self.length * (- estimation) / self.num_of_hashes))
