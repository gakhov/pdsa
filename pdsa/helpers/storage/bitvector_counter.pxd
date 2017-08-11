from libc.stdint cimport uint8_t


cdef extern from "src/BitCounter.h":
   cdef cppclass BitCounter:
        uint8_t counter

        void reset()

        void reset(uint8_t counter_number)
        void inc(uint8_t counter_number)
        void dec(uint8_t counter_number)
        uint8_t value(uint8_t counter_number)


cdef class BitVectorCounter:
    cdef size_t size
    cdef size_t length

    cdef BitCounter * vector

    cpdef size_t sizeof(self)
