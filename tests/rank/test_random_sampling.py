import array
import pytest

from pdsa.rank.random_sampling import RandomSampling


def test_init():
    rs = RandomSampling(16, 5, 3)
    assert repr(rs) == (
        "<RandomSampling (height: 3, "
        "buffers: 16, "
        "capacity: 5)>")

    with pytest.raises(ValueError) as excinfo:
        RandomSampling(16, 0, 3)
    assert str(excinfo.value) == 'The per-buffer capacity is too small'

    with pytest.raises(ValueError) as excinfo:
        RandomSampling(1, 5, 3)
    assert str(excinfo.value) == 'The number of buffers is too small'

    with pytest.raises(ValueError) as excinfo:
        RandomSampling(16, 5, 0)
    assert str(excinfo.value) == 'The height is expected in [2, 15]'


def test_init_from_error():
    error = 0.01
    rs = RandomSampling.create_from_error(0.01)
    assert repr(rs) == (
        "<RandomSampling (height: 5, "
        "buffers: 6, "
        "capacity: 224)>")


def test_length():
    num_of_buffers = 16
    buffer_capacity = 5
    rs = RandomSampling(16, buffer_capacity, 3)

    assert rs.count() == 0, "Non empty data structure from the beginning"
    assert len(rs) == num_of_buffers, "Incorrect number of buffers"

    for element in range(20):
        rs.add(element)

    assert len(rs) == num_of_buffers, "Incorrect number of buffers"


def test_sizeof():
    num_of_buffers = 16
    buffer_capacity = 3
    height = 3
    rs = RandomSampling(num_of_buffers, buffer_capacity, height)

    element_size = array.array('L', [1]).itemsize
    mask_size = array.array('b', [1]).itemsize
    level_size = array.array('I', [1]).itemsize

    total_size = element_size * num_of_buffers * buffer_capacity
    total_size += mask_size * num_of_buffers * buffer_capacity
    total_size += level_size * num_of_buffers

    assert rs.sizeof() == total_size, "Incorrect size in bytes"


def test_queries_from_gakhov_example():
    # NOTE: percentiles and rank given by random sampling are
    # approximated, thus no sense to compare them to the
    # exact values in a test.
    rs = RandomSampling(5, 5, 7)

    dataset = [
        0, 0, 3, 4, 1, 6, 0, 5, 2, 0, 3, 3, 2,
        3, 0, 2, 5, 0, 3, 1, 0, 3, 1, 6, 1
    ]
    for element in dataset:
        rs.add(element)

    rank = rs.inverse_quantile_query(4)
    assert rank == 20, "Incorrect approx. rank"

    percentile65 = rs.quantile_query(0.65)
    assert percentile65 == 3, "Incorrect approx. 65th percentile"

    rank = rs.inverse_quantile_query(5)
    assert rank == 21, "Incorrect approx. rank"

    num_of_values = rs.interval_query(4, 5)
    assert num_of_values == 1, "Incorrect approx. number of values in interval"


def test_queries_from_shrivastava_example():
    # NOTE: percentiles and rank given by random sampling are
    # approximated after the first buffer collapse,
    # thus be careful to compare them to the exact values in a test.
    rs = RandomSampling(3, 4, 7)

    dataset = []

    for i in range(1):
        dataset.append(0)
    for i in range(4):
        dataset.append(2)
    for i in range(6):
        dataset.append(3)
    for i in range(1):
        dataset.append(4)
    for i in range(1):
        dataset.append(5)
    for i in range(1):
        dataset.append(6)
    for i in range(1):
        dataset.append(7)

    for element in dataset:
        rs.add(element)

    median = rs.quantile_query(0.5)
    assert median == 3, "Incorrect approx. median"

    print(rs.debug())
    rank = rs.inverse_quantile_query(3)
    assert rank == 6, "Incorrect approx. rank"

    percentile85 = rs.quantile_query(0.85)
    assert percentile85 == 6, "Incorrect approx. 85th percentile"

    rank = rs.inverse_quantile_query(5)
    assert rank == 12, "Incorrect approx. rank"

    num_of_values = rs.interval_query(3, 5)
    assert num_of_values == 6, "Incorrect approx. number of values in interval"
