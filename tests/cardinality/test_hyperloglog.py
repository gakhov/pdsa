import pytest

from math import sqrt
from pdsa.cardinality.hyperloglog import HyperLogLog


def test_init():
    hll = HyperLogLog(10)
    assert hll.sizeof() == 4096, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        hll = HyperLogLog(2)
    assert str(excinfo.value) == (
        "Precision has to be in range 4...16")


def test_repr():
    hll = HyperLogLog(6)

    assert repr(hll) == (
        "<HyperLogLog (length: 64, precision: 6)>")


def test_add():
    hll = HyperLogLog(10)

    for element in ["test", 1, {"hello": "world"}]:
        hll.add(element)


def test_count():
    precision = 10
    hll = HyperLogLog(precision)
    std = 1.04 / sqrt(1 << precision)

    errors = []

    boundary = 2.5 * (1 << precision)

    cardinality = 0
    for i in range(100000):
        cardinality += 1
        element = "element_{}".format(i)
        hll.add(element)

        if cardinality <= boundary:
            # Ignore small cardinality estimations,
            # they will be tested in another test.
            continue

        error = (cardinality - hll.count()) / float(cardinality)
        errors.append(error)

    avg_error = abs(sum(errors)) / float(len(errors))

    assert avg_error >= 0
    assert avg_error <= std


def test_count_small():
    precision = 6
    hll = HyperLogLog(precision)
    std = 1.04 / sqrt(1 << precision)

    errors = []

    cardinality = 0
    for i in range(100):
        cardinality += 1
        element = "element_{}".format(i)
        hll.add(element)

        error = (cardinality - hll.count()) / float(cardinality)
        errors.append(error)

    avg_error = abs(sum(errors)) / float(len(errors))

    assert avg_error >= 0
    assert avg_error <= std


def test_len():
    hll = HyperLogLog(4)
    assert len(hll) == 16
