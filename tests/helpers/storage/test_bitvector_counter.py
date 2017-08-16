import pytest

from pdsa.helpers.storage.bitvector_counter import BitVectorCounter


def test_bitvector_counter():
    bc = BitVectorCounter(41)

    assert len(bc) == 42
    assert bc.sizeof() == 21, "Unexpected size in bytes"


def test_init():
    bc = BitVectorCounter(41)

    for i in range(len(bc)):
        assert bc[i] == 0, "{}-th value failed to be 0".format(i)

    with pytest.raises(ValueError) as excinfo:
        bc = BitVectorCounter(0)
    assert str(excinfo.value) == 'Length can\'t be 0 or negative'


def test_repr():
    bc = BitVectorCounter(41)

    assert repr(bc) == "<BitVectorCounter (size: 21, length: 42)>"


def test_inc():
    bc = BitVectorCounter(42)

    assert bc[37] == 0
    assert bc[38] == 0

    bc.increment(37)
    assert bc[37] == 1

    bc.decrement(37)
    assert bc[37] == 0

    bc.increment(38)
    assert bc[38] == 1

    bc.decrement(38)
    assert bc[38] == 0


def test_getitem():
    bc = BitVectorCounter(42)

    assert len(bc) == 42
    assert bc[40] == 0

    with pytest.raises(IndexError):
        bc[43]

    with pytest.raises(OverflowError):
        bc[-73]


def test_freeze():
    """Counter should freeze if reached its maximal value.
    For 4-bits counter the maximal value is 0b1111 = 15
    """

    bc = BitVectorCounter(42)

    assert bc[21] == 0
    for i in range(15):
        bc.increment(21)
        assert bc[21] == i + 1

    bc.increment(21)
    assert bc[21] == 15

    assert bc[22] == 0
    for i in range(15):
        bc.increment(22)
        assert bc[22] == i + 1

    bc.increment(22)
    assert bc[22] == 15


def test_decrement_zero():
    bc = BitVectorCounter(42)

    assert bc[21] == 0
    bc.decrement(21)
    assert bc[21] == 0

    assert bc[22] == 0
    bc.decrement(22)
    assert bc[22] == 0
