import pytest

from pdsa.membership.bloom_filter import BloomFilter


def test_init():
    bf = BloomFilter(8000, 3)

    assert bf.sizeof() == 1000, "Unexpected size in bytes"


def test_init_from_capacity():
    bf = BloomFilter.create_from_capacity(5000, 0.02)

    assert bf.sizeof() == 5089, "Unexpected size in bytes"


def test_repr():
    bf = BloomFilter(8000, 3)

    assert repr(bf) == "<BloomFilter (length: 8000, hashes: 3)>"

    bf = BloomFilter.create_from_capacity(5000, 0.02)

    assert repr(bf) == "<BloomFilter (length: 40712, hashes: 5)>"


def test_add():
    bf = BloomFilter(8000, 3)

    for word in ["test", 1, {"hello": "world"}]:
        bf.add(word)
        assert bf.test(word) == 1, "Can't find recently added element"


def test_lookup():
    bf = BloomFilter(8000, 3)

    bf.add("test")
    assert bf.test("test") == 1, "Can't find recently added element"
    assert bf.test("test_test") == 0, "False positive detected"


def test_count():
    bf = BloomFilter(8000, 3)

    assert bf.count() == 0

    bf.add("test")
    assert bf.count() == 1


def test_len():
    bf = BloomFilter(8000, 3)

    assert len(bf) == 8000
