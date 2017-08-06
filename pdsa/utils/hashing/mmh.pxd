from libc.stdint cimport uint32_t

cdef uint32_t mmh3_x86_32bit_bytes(bytes key, uint32_t seed=*)
cdef uint32_t mmh3_x86_32bit_int(int key, uint32_t seed=*)

cpdef uint32_t mmh3_x86_32bit(object key, uint32_t seed=*)
