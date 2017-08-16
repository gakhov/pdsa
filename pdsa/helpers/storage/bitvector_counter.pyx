"""BitVectorCounter.

BitVectorCounter is an array of C++ BitCounters (8 bits long, encoded
two 4-bits counters) that supports flatten navigation.
"""

import cython

from libc.math cimport ceil
from cpython.mem cimport PyMem_Malloc, PyMem_Free

cdef uint8_t NUMBER_OF_SUBCOUNTERS = 2


cdef class BitVectorCounter:
    """Implementation of a vector of 4-bits counters.

    In fact, the bit vector is an array of C++ BitCounters (8 bits long)
    that supports flatten navigation.

    Example
    -------

    >>> from pdsa.helpers.storage.bitvector_counter import BitVector

    >>> bv = BitVectorCounter(48)
    >>> bv[37] = 1
    >>> bv.increment(37)
    >>> print(bv[37])
    >>> bv.decrement(37)
    >>> print(bv[37])


    Attributes
    ----------
    length : :obj:`int`
        The length of the vector's index space.
    size : :obj:`int`
        The size of the array of BitCounters.
    vector : obj
        The array of BitCounters.

    """

    __slots__ = ()

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def __cinit__(self, const size_t length):
        """Allocate and initialize a vector counters.

        Parameters
        ----------
        length : int
            The length of the vector.

        Note
        ----
            It allocates space in blocks of 8 bits (byte),
            that contain 2 (`NUMBER_OF_SUBCOUNTERS`) 4-bits counters,
            therefore the length of the vector can be rounded up
            to efficiently use the allocated memory.

        """
        if length < 1:
            raise ValueError("Length can't be 0 or negative")

        self.length = length + (-length & (NUMBER_OF_SUBCOUNTERS - 1))
        self.size = self.length // NUMBER_OF_SUBCOUNTERS

        self.vector = <BitCounter *>PyMem_Malloc(self.size * sizeof(BitCounter))

        cdef size_t bucket
        for bucket in range(self.size):
            self.vector[bucket].reset()


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def increment(self, const size_t index):
        """Increment counter's value by the index.

        Parameters
        ----------
        index : int
            The index of the counter in the vector.

        Raises
        ------
        IndexError
            If `index` is out of range.

        """
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t counter_number

        bucket, counter_number = divmod(index, NUMBER_OF_SUBCOUNTERS)
        self.vector[bucket].inc(counter_number)


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def decrement(self, const size_t index):
        """Decrement counter's value by the index.

        Parameters
        ----------
        index : int
            The index of the counter in the vector.

        Raises
        ------
        IndexError
            If `index` is out of range.

        """
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t counter_number

        bucket, counter_number = divmod(index, NUMBER_OF_SUBCOUNTERS)
        self.vector[bucket].dec(counter_number)


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def __getitem__(self, const size_t index):
        """Get counter's value by the index.

        Parameters
        ----------
        index : int
            The index of the counter in the vector.

        Returns
        -------
        :obj:`int`
            Counter's value.

        Raises
        ------
        IndexError
            If `index` is out of range.

        """
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t counter_number

        bucket, counter_number = divmod(index, NUMBER_OF_SUBCOUNTERS)
        return self.vector[bucket].value(counter_number)


    def __dealloc__(self):
        PyMem_Free(self.vector)

    def __repr__(self):
        return "<BitVectorCounter (size: {}, length: {})>".format(
            self.size,
            self.length
        )

    def __len__(self):
        """Get length of the vector's index space.

        Returns
        -------
        :obj:`int`
            The length of the vector's index space.

        """
        return self.length

    cpdef size_t sizeof(self):
        """Size of the vector in bytes.

        Returns
        -------
        :obj:`int`
            Number of bytes allocated for the vector.

        """
        return self.size * sizeof(BitCounter)

