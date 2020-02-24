import array
import pytest
import random

from statistics import median

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
    assert str(excinfo.value) == 'The height is expected bigger or equal to 1'


def test_init_from_error():
    error = 0.01
    rs = RandomSampling.create_from_error(0.01)
    assert repr(rs) == (
        "<RandomSampling (height: 7, "
        "buffers: 8, "
        "capacity: 265)>")


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


def test_median_and_rank():
    error = 0.01
    rs = RandomSampling.create_from_error(error)

    print(rs)

    random.seed(42)
    num_of_elements = 100000

    dataset = []
    for i in range(num_of_elements):
        element = random.randrange(0, 16)
        dataset.append(element)
        rs.add(element)

    exact_median = int(median(dataset))

    approx_rank = rs.inverse_quantile_query(exact_median)
    approx_median = rs.quantile_query(0.5)

    rank_lower_boundary = (0.5 - error) * num_of_elements
    rank_upper_boundary = (0.5 + error) * num_of_elements

    assert rank_lower_boundary <= approx_rank <= rank_upper_boundary
    assert approx_median == exact_median
