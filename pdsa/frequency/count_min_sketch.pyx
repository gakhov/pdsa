"""
Count-Min Sketch.

Count–Min Sketch is a simple space-efficient probabilistic data structure
that is used to estimate frequencies of elements in data streams and can
address the Heavy hitters problem. It was presented in 2003 [1] by
Graham Cormode and Shan Muthukrishnan and published in 2005 [2].

References
----------
[1] Cormode, G., Muthukrishnan, S.
    What's hot and what's not: Tracking most frequent items dynamically
    Proceedings of the 22th ACM SIGMOD-SIGACT-SIGART symposium on Principles
    of database systems, San Diego, California - June 09-11, 2003,
    pp. 296–306, ACM New York, NY.
    http://www.cs.princeton.edu/courses/archive/spr04/cos598B/bib/CormodeM-hot.pdf
[2] Cormode, G., Muthukrishnan, S.
    An Improved Data Stream Summary: The Count–Min Sketch and its Applications
    Journal of Algorithms, Vol. 55 (1), pp. 58–75.
    http://dimacs.rutgers.edu/~graham/pubs/papers/cm-full.pdf

"""
import cython

from cpython.array cimport array
from libc.math cimport ceil, log, M_E
from libc.stdint cimport uint64_t, uint32_t, uint8_t
from libc.stdint cimport UINT32_MAX, UINT8_MAX
from libc.stdlib cimport rand, RAND_MAX

from pdsa.helpers.hashing.mmh cimport mmh3_x86_32bit


cdef class CountMinSketch:
    """Count-Min Sketch.

    Count-Min Sketch is simple data structure that allows for the indexing
    of elements from the data stream, results in updating counters,
    and can provide the number of times every element has been indexed.

    Example
    -------

    >>> from pdsa.frequency.count_min_sketch import CountMinSketch

    >>> cms = CountMinSketch(5, 2000)
    >>> cms.add("hello")
    >>> cms.frequency("hello")


    Note
    -----
        This implementation uses MurmurHash3 family of hash functions
        which yields a 32-bit hash value. Thus, the length of the counters
        is expected to be smaller or equal to the (2^{32} - 1), since
        we cannot access elements with indexes above this value.

    Note
    -----
        This implementation uses 32-bits counters that freeze at their
        maximal values (2^{32} - 1).

    Attributes
    ----------
    num_of_counters : :obj:`int`
        The number of counter arrays used in the sketch.
    length_of_counter : :obj:`int`
        The number of counters in each counter array.

    """

    @cython.cdivision(True)
    def __cinit__(self, const uint8_t num_of_counters, const uint32_t length_of_counter):
        """Create sketch from its dimensions.

        Parameters
        ----------
        num_of_counters : :obj:`int`
            The number of counter arrays used in the sketch.
        length_of_counter : :obj:`int`
            The number of counters in each counter array.

        Raises
        ------
        ValueError
            If `num of counters` is less than 1.
        ValueError
            If `length_of_counter` is less than 1.

        """
        if num_of_counters < 1:
            raise ValueError("At least one counter array is required")

        if length_of_counter < 1:
            raise ValueError("The length of the counter array cannot be less then 1")

        self.num_of_counters = num_of_counters
        self.length_of_counter = length_of_counter

        self._length = self.num_of_counters * self.length_of_counter

        self._MAX_COUNTER_VALUE = UINT32_MAX
        self._seeds = array('B', [
            <uint8_t >((rand()/RAND_MAX) * UINT8_MAX)
            for r in range(self.num_of_counters)
        ])
        self._counter = array('I', range(self._length))

        cdef uint64_t index
        for index in xrange(self._length):
            self._counter[index] = 0

    @classmethod
    def create_from_expected_error(cls, const float deviation, const float error):
        """Create sketch from the expected frequency deviation and error probability.

        Parameters
        ----------
        deviation : float
            The error ε in answering the paricular query.
            For example, if we expect 10^7 elements and allow
            the fixed overestimate of 10, the deviation is 10/10^7 = 10^{-6}.
        error : float
            The standard error δ (0 < error < 1).

        Note
        ----
            The Count–Min Sketch is approximate and probabilistic at the same
            time, therefore two parameters, the error ε in answering the paricular
            query and the error probability δ, affect the space and time
            requirements. In fact, it provides the guarantee that the estimation
            error for frequencies will not exceed ε x n
            with probability at least 1 – δ.

        Raises
        ------
        ValueError
            If `deviation` is smaller than 10^{-10}.
        ValueError
            If `error` is not in range (0, 1).

        """
        if deviation <= 0.0000000001:
            raise ValueError("Deviation is too small. Not enough counters")

        if error <= 0 or error >= 1:
            raise ValueError("Error rate shell be in (0, 1)")

        cdef uint8_t num_of_counters = <uint8_t > (ceil(-log(error)))
        cdef uint32_t length_of_counter = <uint32_t > (ceil(M_E / deviation))

        return cls(max(1, num_of_counters), max(1, length_of_counter))

    cdef uint32_t _hash(self, object key, uint8_t seed):
        return mmh3_x86_32bit(key, seed)

    def __dealloc__(self):
        pass

    cdef bint _increment_counter(self, const uint64_t index):
        """Increment counter if the value doesn't exceed maximal allowed.

        Parameters
        ----------
        index : obj:`int`
            The index of the counter to be incremented.

        Note
        ----
            When counter reaches its maximal value, we simple freeze it there.

        """
        if self._counter[index] < self._MAX_COUNTER_VALUE:
            self._counter[index] += 1
            return True
        return False

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef void add(self, object element) except *:
        """Index element into the sketch.

        Parameters
        ----------
        element : obj
            The element to be indexed into the sketch.

        """
        cdef uint8_t counter_index
        cdef uint32_t element_index
        cdef uint8_t seed
        cdef uint64_t index
        for counter_index in range(self.num_of_counters):
            seed = self._seeds[counter_index]
            element_index = self._hash(element, seed) % self.length_of_counter
            index = counter_index * (self.length_of_counter - 1) + element_index
            self._increment_counter(index)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cpdef uint32_t frequency(self, object element) except *:
        """Estimate frequency of element.

        Parameters
        ----------
        element : obj
            The element to estimate the frequency for.

        Returns
        -------
        uint32_t
            The frequency of the element.

        """
        cdef uint8_t counter_index
        cdef uint32_t element_index
        cdef uint8_t seed
        cdef uint64_t index
        cdef uint32_t frequency = self._MAX_COUNTER_VALUE
        for counter_index in range(self.num_of_counters):
            seed = self._seeds[counter_index]
            element_index = self._hash(element, seed) % self.length_of_counter
            index = counter_index * (self.length_of_counter - 1) + element_index
            frequency = min(frequency, self._counter[index])
        return frequency

    cpdef size_t sizeof(self):
        """Size of the sketch in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the sketch.

        """
        return self._length * sizeof(uint32_t)

    def __repr__(self):
        return "<CountMinSketch ({} x {})>".format(
            self.num_of_counters,
            self.length_of_counter
        )

    def __len__(self):
        """Get length of the filter.

        Returns
        -------
        :obj:`int`
            The length of the filter.

        """
        return self._length



    def debug(self):
        """Return sketch for debug purposes."""
        return self._counter
