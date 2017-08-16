import pytest

from pdsa.helpers.storage.bitvector import BitVector


def test_bitvector():
    bv = BitVector(42)

    assert len(bv) == 48
    assert bv.sizeof() == 6, "Unexpected size in bytes"


def test_init():
    bv = BitVector(42)

    for i in range(len(bv)):
        assert bv[i] == 0, "{}-th value failed to be 0".format(i)

    with pytest.raises(ValueError) as excinfo:
        bv = BitVector(0)
    assert str(excinfo.value) == 'Length can\'t be 0 or negative'


def test_repr():
    bv = BitVector(42)

    assert repr(bv) == "<BitVector (size: 6, length: 48)>"


def test_setitem():
    bv = BitVector(48)

    assert bv[37] == 0

    bv[37] = 1
    assert bv[37] == 1

    bv[37] = 0
    assert bv[37] == 0

    with pytest.raises(IndexError):
        bv[73] = 1

    with pytest.raises(OverflowError):
        bv[-73] = 1


def test_getitem():
    bv = BitVector(48)

    assert len(bv) == 48
    assert bv[47] == 0

    with pytest.raises(IndexError):
        bv[48] == 0

    with pytest.raises(OverflowError):
        bv[-73] = 1


def test_count():
    bv = BitVector(48)

    assert bv.count() == 0

    bv[42] = 1
    assert bv.count() == 1
