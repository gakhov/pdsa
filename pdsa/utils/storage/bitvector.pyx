from cpython.mem cimport PyMem_Malloc, PyMem_Free


cdef uint8_t BITFIELD_BITSIZE = sizeof(BitField) * 8

cdef class BitVector:

    __slots__ = ()

    def __cinit__(self, const size_t length):
        """Allocate and initialize the bit vector.

        NOTE: we allocate space in chucks of 8 bits (byte, size of BitField),
        so the length of the vector can be rounded up.

        It's guaranteed that all bits in newly created structure will
        be cleared (set to 0).
        """

        cdef size_t quotient
        cdef int remainder

        quotient, remainder = divmod(length, BITFIELD_BITSIZE)

        self.size = quotient if remainder == 0 else quotient + 1
        self.length = self.size * BITFIELD_BITSIZE

        self.vector = <BitField *>PyMem_Malloc(self.size * sizeof(BitField))
        for bucket in range(self.size):
            self.vector[bucket].clear()

    def __getitem__(self, const size_t index):
        if index > self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef int bucket
        cdef uint8_t bit

        bucket, bit = divmod(index, BITFIELD_BITSIZE)
        return self.vector[bucket].get_bit(bit)

    def __setitem__(self, const size_t index, const bint flag):
        if index > self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef int bucket
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
        return self.length

    def sizeof(self):
        return self.size * sizeof(BitField)
