import pytest

from math import sqrt
from pdsa.cardinality.probabilistic_counter import ProbabilisticCounter


def test_init():
    pc = ProbabilisticCounter(10)
    assert pc.sizeof() == 40, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        pc = ProbabilisticCounter(0)
    assert str(excinfo.value) == 'At least one simple counter is required'


def test_repr():
    pc = ProbabilisticCounter(10)

    assert repr(pc) == (
        "<ProbabilisticCounter (length: 320, num_of_counters: 10)>")


def test_add():
    pc = ProbabilisticCounter(10)

    for word in ["test", 1, {"hello": "world"}]:
        pc.add(word)


def test_count():
    num_of_counters = 256
    pc = ProbabilisticCounter(num_of_counters)
    std = 0.78 / sqrt(num_of_counters)

    errors = []

    boundary = 20 * num_of_counters

    cardinality = 0
    for i in range(10000):
        cardinality += 1
        element = "element_{}".format(i)
        pc.add(element)

        if cardinality < boundary:
            # For small cardinalities we need to use correction,
            # that we will test in another case.
            continue

        error = (cardinality - pc.count()) / float(cardinality)
        errors.append(error)

    avg_error = abs(sum(errors)) / float(len(errors))

    assert avg_error >= 0
    assert avg_error <= std


def test_count_small():
    num_of_counters = 256
    pc = ProbabilisticCounter(
        num_of_counters, with_small_cardinality_correction=True)

    std = 0.78 / sqrt(num_of_counters)

    errors = []

    cardinality = 0
    for i in range(1000):
        cardinality += 1
        element = "element_{}".format(i)
        pc.add(element)

        error = (cardinality - pc.count()) / float(cardinality)
        errors.append(error)

    avg_error = abs(sum(errors)) / float(len(errors))

    assert avg_error >= 0
    assert avg_error <= 2 * std  # Even with correction, still not so good


def test_len():
    pc = ProbabilisticCounter(10)
    assert len(pc) == 320
