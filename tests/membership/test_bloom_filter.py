import pytest

from pdsa.membership.bloom_filter import BloomFilter


def test_init():
    bf = BloomFilter(8000, 3)
    assert bf.sizeof() == 1000, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        bf = BloomFilter(8000, 0)
    assert str(excinfo.value) == 'At least one hash function is required'

    with pytest.raises(ValueError) as excinfo:
        bf = BloomFilter(0, 5)
    assert str(excinfo.value) == 'Filter length can\'t be 0 or negative'


def test_init_from_capacity():
    bf = BloomFilter.create_from_capacity(5000, 0.02)
    assert bf.sizeof() == 5089, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        bf = BloomFilter.create_from_capacity(5000, 2)
    assert str(excinfo.value) == 'Error rate shell be in (0, 1)'

    with pytest.raises(ValueError) as excinfo:
        bf = BloomFilter.create_from_capacity(0, 0.02)
    assert str(excinfo.value) == 'Filter capacity can\'t be 0 or negative'

    bf = BloomFilter.create_from_capacity(5000, 0.999)
    assert len(bf) == 16


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

    bf.add("test")
    assert bf.count() == 1

    bf.add("test2")
    assert bf.count() == 2


def test_count_when_full():
    length = 8
    num_of_hashes = 2

    bf = BloomFilter(length, num_of_hashes)

    # We index 20 strings to kind of guarantee that
    # filter of length 8 is full afterwards.
    # NOTE: In perfect situation, only 4 items are required,
    # but we don't know which ones.
    for i in range(20):
        bf.add("test{}".format(i))

    assert bf.count() == length / num_of_hashes


def test_len():
    bf = BloomFilter(8000, 3)
    assert len(bf) == 8000

    bf = BloomFilter(8001, 3)
    assert len(bf) == 8008
