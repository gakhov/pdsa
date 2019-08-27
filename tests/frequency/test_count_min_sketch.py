import pytest

from pdsa.frequency.count_min_sketch import CountMinSketch


def test_init():
    cms = CountMinSketch(2, 4)
    assert cms.sizeof() == 32, 'Unexpected size in bytes'

    with pytest.raises(ValueError) as excinfo:
        cms = CountMinSketch(0, 5)
    assert str(excinfo.value) == 'At least one counter array is required'

    with pytest.raises(ValueError) as excinfo:
        cms = CountMinSketch(5, 0)
    assert str(excinfo.value) == (
        'The length of the counter array cannot be less then 1'
    )


def test_create_from_expected_error():
    cms = CountMinSketch.create_from_expected_error(0.000001, 0.01)
    assert repr(cms) == "<CountMinSketch (5 x 2718282)>"
    assert len(cms) == 13591410, 'Unexpected length'
    assert cms.sizeof() == 54365640, 'Unexpected size in bytes'

    with pytest.raises(ValueError) as excinfo:
        cms = CountMinSketch.create_from_expected_error(0.001, 2)
    assert str(excinfo.value) == 'Error rate shell be in (0, 1)'

    with pytest.raises(ValueError) as excinfo:
        cs = CountMinSketch.create_from_expected_error(0.0000000000001, 0.02)
    assert str(excinfo.value) == 'Deviation is too small. Not enough counters'


def test_repr():
    cms = CountMinSketch(2, 4)
    assert repr(cms) == "<CountMinSketch (2 x 4)>"

    cms = CountMinSketch.create_from_expected_error(0.1, 0.01)
    assert repr(cms) == "<CountMinSketch (5 x 28)>"


def test_add():
    cms = CountMinSketch(4, 100)

    for word in ["test", 1, {"hello": "world"}]:
        cms.add(word)
        assert cms.frequency(word) == 1, "Can't find frequency for element"


def test_frequency():
    cms = CountMinSketch(4, 100)

    cms.add("test")
    assert cms.frequency("test") == 1, "Can't find recently added element"
    assert cms.frequency("test_test") == 0, "False positive detected"


def test_len():
    cms = CountMinSketch(2, 4)
    assert len(cms) == 8
