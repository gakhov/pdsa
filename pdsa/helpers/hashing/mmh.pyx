"""Cython interface to MurmurHash3 C++ code by A. Appleby

MurmurHash3 is a non-cryptographic hash function.
https://github.com/aappleby/smhasher/wiki/MurmurHash3

For probabilistic data structures the 32-bit version is used
that produces low latency hash values.
"""
from libc.stdint cimport uint32_t

cdef extern from "src/MurmurHash3.h":
   void MurmurHash3_x86_32(void* key, int len, uint32_t seed, void* out)


cdef uint32_t mmh3_x86_32bit_bytes(bytes key, uint32_t seed=42):
    cdef uint32_t hash_value
    MurmurHash3_x86_32(<char*> key, len(key), seed, &hash_value)
    return hash_value

cdef uint32_t mmh3_x86_32bit_int(int key, uint32_t seed=42):
    cdef uint32_t hash_value
    MurmurHash3_x86_32(&key, sizeof(key), seed, &hash_value)
    return hash_value


cpdef uint32_t mmh3_x86_32bit(object key, uint32_t seed=42):
    """Compute x86 32bit MurmurHash3 hash value.

    Parameters
    ----------
    key : obj
        The object to compute the hash value from.
    seed : :obj:`int`
        The seed to support reproducable hash calculation.

    """
    if isinstance(key, int):
        return mmh3_x86_32bit_int(<int>key, seed)

    if isinstance(key, bytes):
        return mmh3_x86_32bit_bytes(key, seed)

    return mmh3_x86_32bit_bytes(repr(key).encode("utf-8"), seed)

