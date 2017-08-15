import pytest

from pdsa.membership.counting_bloom_filter import CountingBloomFilter


def test_init():
    bf = CountingBloomFilter(8000, 3)

    assert bf.sizeof() == 5000, "Unexpected size in bytes"


def test_init_from_capacity():
    bf = CountingBloomFilter.create_from_capacity(5000, 0.02)

    assert bf.sizeof() == 25445, "Unexpected size in bytes"


def test_repr():
    bf = CountingBloomFilter(8000, 3)

    assert repr(bf) == "<CountingBloomFilter (length: 8000, hashes: 3)>"

    bf = CountingBloomFilter.create_from_capacity(5000, 0.02)

    assert repr(bf) == "<CountingBloomFilter (length: 40712, hashes: 5)>"


def test_add():
    bf = CountingBloomFilter(8000, 3)

    for word in ["test", 1, {"hello": "world"}]:
        bf.add(word)
        assert bf.test(word) == 1, "Can't find recently added element"


def test_lookup():
    bf = CountingBloomFilter(8000, 3)

    bf.add("test")
    assert bf.test("test") == 1, "Can't find recently added element"
    assert bf.test("test_test") == 0, "False positive detected"


def test_count():
    bf = CountingBloomFilter(8000, 3)

    assert bf.count() == 0

    bf.add("test")
    assert bf.count() == 1


def test_len():
    bf = CountingBloomFilter(8000, 3)

    assert len(bf) == 8000


def test_delete():
    bf = CountingBloomFilter(8000, 3)

    assert bf.remove("test") is False

    bf.add("test")
    assert bf.remove("test") is True, "Can't remove element"
    assert bf.remove("test") is False, "Element wasn't in fact removed"
