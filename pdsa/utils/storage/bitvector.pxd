from libc.stdint cimport uint8_t


cdef extern from "src/BitField.h":
   cdef cppclass BitField:
        uint8_t field

        void clear()
        uint8_t count()

        void set_bit(uint8_t bit_number, bint flag)
        bint get_bit(uint8_t bit_number)


cdef class BitVector:
    cdef size_t size
    cdef size_t length

    cdef BitField * vector

    cpdef size_t count(self)
    cpdef size_t sizeof(self)
