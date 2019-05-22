import pytest

from pdsa.cardinality.linear_counter import LinearCounter


def test_init():
    lc = LinearCounter(8000)
    assert lc.sizeof() == 1000, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        lc = LinearCounter(0)
    assert str(excinfo.value) == 'Counter length can\'t be 0 or negative'


def test_repr():
    lc = LinearCounter(8000)

    assert repr(lc) == "<LinearCounter (length: 8000)>"


def test_add():
    lc = LinearCounter(8000)

    for word in ["test", 1, {"hello": "world"}]:
        lc.add(word)


def test_count_small():
    lc = LinearCounter(100000)

    assert lc.count() == 0

    lc.add("test")
    assert lc.count() == 1

    lc.add("test")
    assert lc.count() == 1

    lc.add("test2")
    assert lc.count() == 2


def test_count():
    lc = LinearCounter(100000)

    errors = []

    cardinality = 0
    for i in range(100):
        cardinality += 1
        element = "element_{}".format(i)
        lc.add(element)

        error = abs(cardinality - lc.count()) / float(cardinality)
        errors.append(error)

    avg_error = sum(errors) / float(len(errors))

    assert avg_error >= 0
    assert avg_error <= 0.1


def test_len():
    lc = LinearCounter(8000)
    assert len(lc) == 8000

    lc = LinearCounter(8001)
    assert len(lc) == 8008
