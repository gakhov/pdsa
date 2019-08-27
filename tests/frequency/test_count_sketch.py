import pytest

from pdsa.frequency.count_sketch import CountSketch


def test_init():
    cs = CountSketch(2, 4)
    assert cs.sizeof() == 32, 'Unexpected size in bytes'

    with pytest.raises(ValueError) as excinfo:
        cs = CountSketch(0, 5)
    assert str(excinfo.value) == 'At least one counter array is required'

    with pytest.raises(ValueError) as excinfo:
        cs = CountSketch(5, 0)
    assert str(excinfo.value) == (
        'The length of the counter array cannot be less then 1'
    )


def test_create_from_expected_error():
    cs = CountSketch.create_from_expected_error(0.0001, 0.01)
    assert repr(cs) == "<CountSketch (5 x 271828209)>"
    assert len(cs) == 1359141045, 'Unexpected length'
    assert cs.sizeof() == 5436564180, 'Unexpected size in bytes'

    with pytest.raises(ValueError) as excinfo:
        cs = CountSketch.create_from_expected_error(0.001, 2)
    assert str(excinfo.value) == 'Error rate shell be in (0, 1)'

    with pytest.raises(ValueError) as excinfo:
        cs = CountSketch.create_from_expected_error(0.0000000001, 0.02)
    assert str(excinfo.value) == 'Deviation is too small. Not enough counters'


def test_repr():
    cs = CountSketch(2, 4)
    assert repr(cs) == "<CountSketch (2 x 4)>"

    cs = CountSketch.create_from_expected_error(0.1, 0.01)
    assert repr(cs) == "<CountSketch (5 x 272)>"


def test_add():
    cs = CountSketch(4, 100)

    for word in ["test", 1, {"hello": "world"}]:
        cs.add(word)
        assert cs.frequency(word) == 1, "Can't find frequency for element"


def test_frequency():
    cs = CountSketch(4, 100)

    cs.add("test")
    assert cs.frequency("test") == 1, "Can't find recently added element"
    assert cs.frequency("test_test") == 0, "False positive detected"


def test_len():
    cs = CountSketch(2, 4)
    assert len(cs) == 8
