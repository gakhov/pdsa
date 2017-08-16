"""BitVector.

BitVector is an array of C++ BitFields (8 bits long) that
supports flatten navigation.
"""

import cython

from libc.math cimport ceil
from cpython.mem cimport PyMem_Malloc, PyMem_Free


cdef uint8_t BITFIELD_BITSIZE = sizeof(BitField) * 8

cdef class BitVector:
    """Implementation of a bit vector.

    In fact, the bit vector is an array of C++ BitFields (8 bits long)
    that supports flatten navigation.

    Example
    -------

    >>> from pdsa.helpers.storage.bitvector import BitVector

    >>> bv = BitVector(48)
    >>> bv[37] = 1
    >>> print(bv[37])


    Attributes
    ----------
    length : :obj:`int`
        The length of the vector's index space.
    size : :obj:`int`
        The size of the array of BitFields.
    vector : obj
        The array of BitFields.

    """
    __slots__ = ()

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def __cinit__(self, const size_t length):
        """Allocate and initialize a bit vector.

        Parameters
        ----------
        length : int
            The length of the vector.

        Note
        ----
            It allocates space in blocks of 8 bits (byte, size of BitField),
            therefore the length of the vector can be rounded up to
            efficiently use the allocated memory.

        Note
        ----
            It's guaranteed that all bits in newly created structure will
            be cleared (set to 0).

        """
        if length < 1:
            raise ValueError("Length can't be 0 or negative")

        self.length = length + (-length & (BITFIELD_BITSIZE - 1))
        self.size = self.length // BITFIELD_BITSIZE

        self.vector = <BitField *>PyMem_Malloc(self.size * sizeof(BitField))

        cdef size_t bucket
        for bucket in range(self.size):
            self.vector[bucket].clear()

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def __getitem__(self, const size_t index):
        """Get element (bit value) by the index.

        Parameters
        ----------
        index : int
            The index of the element in the vector.

        Returns
        -------
        :obj:`bool`
            True if bit is set, False otherwise.

        Raises
        ------
        IndexError
            If `index` is out of range.

        """
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t bit

        bucket, bit = divmod(index, BITFIELD_BITSIZE)
        return self.vector[bucket].get_bit(bit)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    def __setitem__(self, const size_t index, const bint flag):
        """Set element (bit value) by the index.

        Parameters
        ----------
        index : int
            The index of the element in the vector.

        Raises
        ------
        IndexError
            If `index` is out of range.

        """
        if index >= self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef size_t bucket
        cdef uint8_t bit

        bucket, bit = divmod(index, BITFIELD_BITSIZE)
        self.vector[bucket].set_bit(bit, flag)

    def __dealloc__(self):
        PyMem_Free(self.vector)

    def __repr__(self):
        return "<BitVector (size: {}, length: {})>".format(
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
        return self.size * sizeof(BitField)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef size_t count(self):
        """Count number of set bits in the vector.

        Returns
        -------
        :obj:`int`
            Number of set bits in the vector.

        """
        cdef size_t num_of_bits = 0

        cdef size_t bucket
        for bucket in range(self.size):
            num_of_bits += self.vector[bucket].count()

        return num_of_bits

