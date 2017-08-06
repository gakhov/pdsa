from cpython.mem cimport PyMem_Malloc, PyMem_Free


cdef uint8_t BITFIELD_BITSIZE = sizeof(BitField) * 8

cdef class BitPosition:
    __slots__ = ()

    def __cinit__(self, size_t bucket, uint8_t bit):
        self.bucket = bucket
        self.bit = bit


cdef class BitVector:

    __slots__ = ()
   
    def __cinit__(self, size_t length):
        """Allocate and initialize the bit vector.

        NOTE: we allocate space in chucks of 8 bits (byte, size of BitField),
        so the length of the vector can be rounded up.

        It's guaranteed that all bits in newly created structure will
        be cleared (set to 0).
        """
        self.size = length // BITFIELD_BITSIZE
        if length % BITFIELD_BITSIZE > 0:
            self.size += 1

        self.length = self.size * BITFIELD_BITSIZE

        self.vector = <BitField *>PyMem_Malloc(self.size * sizeof(BitField))
        for bucket in range(self.size):
            self.vector[bucket].clear()

    cdef BitPosition _get_bit_position(self, const size_t index):
        """Calculate 2D position in the vector using flat index."""
        cdef int bucket = index // BITFIELD_BITSIZE
        cdef uint8_t bit = index % BITFIELD_BITSIZE

        return BitPosition(bucket, bit)

    def __getitem__(self, const size_t index):
        if index > self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef BitPosition position = self._get_bit_position(index)
        return self.vector[position.bucket].get_bit(position.bit)

    def __setitem__(self, const size_t index, const bint flag):
        if index > self.length:
            raise IndexError("Index {} out of range".format(index))

        cdef BitPosition position = self._get_bit_position(index)
        self.vector[position.bucket].set_bit(position.bit, flag)

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
