import pytest

from pdsa.rank.qdigest import QuantileDigest


def test_init():
    qd = QuantileDigest(16, 3)
    assert repr(qd) == (
        "<QuantileDigest (compression: 3, "
        "range: [0, 65535], "
        "length: 0)>")

    with pytest.raises(ValueError) as excinfo:
        QuantileDigest(16, 0)
    assert str(excinfo.value) == 'Compression factor is too small'

    with pytest.raises(ValueError) as excinfo:
        QuantileDigest(64, 5)
    assert str(excinfo.value) == 'Only ranges up to 2^{32} are supported'


def test_length():
    qd = QuantileDigest(3, 3)
    assert len(qd) == 0, "Non-zero length of empty q-digest"

    for i in range(10):
        qd.add(0)

    assert len(qd) == 4, "Incorrect length"


def test_sizeof():
    qd = QuantileDigest(3, 3)
    assert qd.sizeof() == 0, "Non-zero size of empty q-digest"

    for i in range(10):
        qd.add(0)

    assert qd.sizeof() == len(qd) * 16, "Unexpected size in bytes"

    for i in range(5):
        qd.add(0)

    assert qd.sizeof() == len(qd) * 16, "Unexpected size in bytes"

    for i in range(5):
        qd.add(1)

    assert qd.sizeof() == len(qd) * 16, "Unexpected size in bytes"

    qd.compress()

    assert qd.sizeof() == len(qd) * 16, "Unexpected size in bytes"


def test_add():
    range_in_bits = 3
    qd = QuantileDigest(range_in_bits, 5)

    for i in range(1 << range_in_bits):
        qd.add(i, False)

    assert len(qd) == (1 << (range_in_bits + 1)) - 1, "Incorrect length"
    assert qd.count() == 1 << range_in_bits, "Invalid tree"

    qd = QuantileDigest(3, 5)
    with pytest.raises(ValueError) as excinfo:
        qd.add(1024)
    assert str(excinfo.value) == 'Value out of range'


def test_compress():
    qd = QuantileDigest(3, 3)

    for i in range(10):
        qd.add(0)

    assert len(qd) == 4, "Incorrect number of nodes"
    assert qd.count() == 10, "Invalid counts"

    size_before_compress = qd.sizeof()

    qd.compress()

    assert qd.sizeof() < size_before_compress, "Compress didn't reduce size"
    assert len(qd) == 1, "Incorrect number of nodes"
    assert qd.count() == 10, "Invalid counts"

    qd.add(7)

    assert len(qd) == 5, "Incorrect number of nodes"
    assert qd.count() == 11, "Invalid counts"

    size_before_compress = qd.sizeof()

    qd.compress()

    assert qd.sizeof() < size_before_compress, "Compress didn't reduce size"
    assert len(qd) == 2, "Incorrect number of nodes"
    assert qd.count() == 11, "Invalid counts"


def test_compress_from_shrivastava_example():
    qd = QuantileDigest(3, 5)

    for i in range(1):
        qd.add(0)
    for i in range(4):
        qd.add(2)
    for i in range(6):
        qd.add(3)
    for i in range(1):
        qd.add(4)
    for i in range(1):
        qd.add(5)
    for i in range(1):
        qd.add(6)
    for i in range(1):
        qd.add(7)

    assert len(qd) == 14, "Incorrect number of nodes"
    assert qd.count() == 15, "Invalid counts"

    qd.compress()

    assert len(qd) == 5, "Incorrect number of nodes"
    assert qd.count() == 15, "Invalid counts"


def test_queries_from_shrivastava_example():
    # NOTE: percentiles and rank given by q-digest are
    # approximated, thus no sense to compare them to the
    # exact values in a test.
    qd = QuantileDigest(3, 5)

    for i in range(1):
        qd.add(0)
    for i in range(4):
        qd.add(2)
    for i in range(6):
        qd.add(3)
    for i in range(1):
        qd.add(4)
    for i in range(1):
        qd.add(5)
    for i in range(1):
        qd.add(6)
    for i in range(1):
        qd.add(7)

    qd.compress()

    median = qd.quantile_query(0.5)
    assert median == 3, "Incorrect approx. median"

    rank = qd.inverse_quantile_query(3)
    assert rank == 4, "Incorrect approx. rank"

    percentile85 = qd.quantile_query(0.85)
    assert percentile85 == 7, "Incorrect approx. 85th percentile"

    rank = qd.inverse_quantile_query(5)
    assert rank == 10, "Incorrect approx. rank"

    num_of_values = qd.interval_query(3, 5)
    assert num_of_values == 6, "Incorrect approx. number of values in interval"


def test_merge_empty():
    qd1 = QuantileDigest(3, 5)
    q1_counts = qd1.count()
    assert q1_counts == 0, "Incorrect number of elements"

    qd2 = QuantileDigest(3, 5)
    q2_counts = qd2.count()
    assert q2_counts == 0, "Incorrect number of elements"

    qd1.merge(qd2)

    assert len(qd1) == 0, "Invalid length"
    assert qd1.count() == 0, "Incorrect number of elements"


def test_merge_unmergeable():
    qd1 = QuantileDigest(3, 5)
    qd2 = QuantileDigest(3, 2)

    with pytest.raises(ValueError) as excinfo:
        qd1.merge(qd2)
    assert str(excinfo.value) == 'Compression factors have to be equal'

    qd1 = QuantileDigest(3, 5)
    qd2 = QuantileDigest(4, 5)

    with pytest.raises(ValueError) as excinfo:
        qd1.merge(qd2)
    assert str(excinfo.value) == 'Ranges have to be equal'


def test_merge():
    qd1 = QuantileDigest(3, 5)

    for i in range(8):
        qd1.add(0)
    for i in range(8):
        qd1.add(1)
    for i in range(4):
        qd1.add(2)
    for i in range(1):
        qd1.add(3)
    for i in range(5):
        qd1.add(4)
    for i in range(3):
        qd1.add(5)
    for i in range(5):
        qd1.add(6)
    for i in range(2):
        qd1.add(7)

    q1_counts = qd1.count()
    qd1.compress()

    qd2 = QuantileDigest(3, 5)

    for i in range(10):
        qd2.add(0)
    for i in range(12):
        qd2.add(1)
    for i in range(8):
        qd2.add(2)
    for i in range(20):
        qd2.add(3)

    q2_counts = qd2.count()
    qd2.compress()

    qd1.merge(qd2)
    assert qd1.count() == q1_counts + q2_counts, "Incorrect counts"
    assert len(qd1) == 6, "Incorrect length"
