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
    assert str(excinfo.value) == 'The buffers\' capacity is too small'

    with pytest.raises(ValueError) as excinfo:
        RandomSampling(1, 5, 3)
    assert str(excinfo.value) == 'The number of buffers is too small'

    with pytest.raises(ValueError) as excinfo:
        RandomSampling(16, 5, 0)
    assert str(excinfo.value) == 'The height is too small'


def test_length():
    buffer_capacity = 5
    rs = RandomSampling(16, buffer_capacity, 3)

    assert len(rs) == 0, "Incorrect number of non-empty buffers"

    num_of_elements = 11  # keep small to stay with level 0
    for element in range(num_of_elements):
        rs.add(element)

    expected_size = num_of_elements // buffer_capacity
    assert len(rs) == expected_size, "Incorrect number of buffers"


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
    total_size += mask_size * num_of_buffers
    total_size += level_size * num_of_buffers

    assert rs.sizeof() == total_size, "Incorrect size in bytes"


# def test_consume():
#     dataset = iter(range(1, 1000))

#     rs = RandomSampling(16, 5, 3)

#     for i in range(1 << range_in_bits):
#         rs.add(i, False)

#     assert len(rs) == (1 << (range_in_bits + 1)) - 1, "Incorrect length"
#     assert rs.count() == 1 << range_in_bits, "Invalid tree"

#     rs = RandomSampling(3, 5)
#     with pytest.raises(ValueError) as excinfo:
#         rs.add(1024)
#     assert str(excinfo.value) == 'Value out of range'

def test_queries_from_shrivastava_example():
    # NOTE: percentiles and rank given by Random Sampling are
    # approximated after the first buffer collapse,
    # thus be careful to compare them to the exact values in a test.
    rs = RandomSampling(16, 5, 3)

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

    from statistics import median as exact_median

    median = rs.quantile_query(0.5)
    assert median == 3, "Incorrect approx. median"

    rank = rs.inverse_quantile_query(3)
    assert rank == 4, "Incorrect approx. rank"

    percentile85 = rs.quantile_query(0.85)
    assert percentile85 == 5, "Incorrect approx. 85th percentile"

    rank = rs.inverse_quantile_query(5)
    assert rank == 10, "Incorrect approx. rank"

    num_of_values = rs.interval_query(3, 5)
    assert num_of_values == 8, "Incorrect approx. number of values in interval"
