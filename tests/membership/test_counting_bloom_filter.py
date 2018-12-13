import pytest

from pdsa.membership.counting_bloom_filter import CountingBloomFilter


def test_init():
    bf = CountingBloomFilter(8000, 3)
    assert bf.sizeof() == 5000, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        bf = CountingBloomFilter(8000, 0)
    assert str(excinfo.value) == 'At least one hash function is required'

    with pytest.raises(ValueError) as excinfo:
        bf = CountingBloomFilter(0, 5)
    assert str(excinfo.value) == 'Filter length can\'t be 0 or negative'


def test_init_from_capacity():
    bf = CountingBloomFilter.create_from_capacity(5000, 0.02)
    assert bf.sizeof() == 25445, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        bf = CountingBloomFilter.create_from_capacity(5000, 2)
    assert str(excinfo.value) == 'Error rate shell be in (0, 1)'

    with pytest.raises(ValueError) as excinfo:
        bf = CountingBloomFilter.create_from_capacity(0, 0.02)
    assert str(excinfo.value) == 'Filter capacity can\'t be 0 or negative'

    bf = CountingBloomFilter.create_from_capacity(5000, 0.999)
    assert len(bf) == 16


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

    bf.add("test")
    assert bf.count() == 1

    bf.add("test2")
    assert bf.count() == 2


def test_count_when_full():
    length = 8
    num_of_hashes = 2

    bf = CountingBloomFilter(length, num_of_hashes)

    # We index 20 strings to kind of guarantee that
    # filter of length 8 is full afterwards.
    # NOTE: In perfect situation, only 4 items are required,
    # but we don't know which ones.
    for i in range(20):
        bf.add("test{}".format(i))

    assert bf.count() == length / num_of_hashes


def test_len():
    bf = CountingBloomFilter(8000, 3)
    assert len(bf) == 8000

    bf = CountingBloomFilter(8001, 3)
    assert len(bf) == 8008


def test_delete():
    bf = CountingBloomFilter(8000, 3)

    assert bf.remove("test") is False

    bf.add("test")
    assert bf.remove("test") is True, "Can't remove element"
    assert bf.remove("test") is False, "Element wasn't in fact removed"
