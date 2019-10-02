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

    # Actually, for small cardinalities we have no estimate. It is
    # just seems that the the errors have to be bigger.
    std = 0.78 / sqrt(num_of_counters)

    boundary = 2 * num_of_counters

    errors = []

    cardinality = 0
    for i in range(boundary):
        cardinality += 1
        element = "element_{}".format(i)
        pc.add(element)

        error = (cardinality - pc.count()) / float(cardinality)
        errors.append(error)

    avg_error = abs(sum(errors)) / float(len(errors))

    assert avg_error >= 0
    assert avg_error <= 3 * std  # There is no known theoretical expectation.


def test_correction():
    pc_with_corr = ProbabilisticCounter(
        256, with_small_cardinality_correction=True)
    pc = ProbabilisticCounter(256)

    errors = []
    errors_with_corr = []

    cardinality = 0
    for i in range(100):
        cardinality += 1
        element = "element_{}".format(i)
        pc_with_corr.add(element)
        pc.add(element)

        error_with_corr = (
            cardinality - pc_with_corr.count()) / float(cardinality)
        errors_with_corr.append(error_with_corr)

        error = abs(cardinality - pc.count()) / float(cardinality)
        errors.append(error)

    avg_error_with_corr = abs(sum(errors_with_corr)) / \
        float(len(errors_with_corr))
    avg_error = abs(sum(errors)) / float(len(errors))

    assert avg_error_with_corr < avg_error


def test_len():
    pc = ProbabilisticCounter(10)
    assert len(pc) == 320
