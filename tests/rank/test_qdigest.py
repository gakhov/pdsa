import pytest

from pdsa.rank.qdigest import QuantileDigest


def test_init():
    qd = QuantileDigest(16, 3)
    assert repr(qd) == (
        "<QuantileDigest (compression: 3, "
        "range: [0, 65535], with_hashing: off, "
        "length: 0)>")

    with pytest.raises(ValueError) as excinfo:
        QuantileDigest(16, 0)
    assert str(excinfo.value) == 'Compression factor is too small'

    with pytest.raises(ValueError) as excinfo:
        QuantileDigest(64, 5, True)
    assert str(excinfo.value) == 'Only 32-bit hashing is supported'

    with pytest.raises(ValueError) as excinfo:
        QuantileDigest(64, 5, False)
    assert str(excinfo.value) == 'Only ranges up to 2^{32} are supported'


def test_init_with_hashing():
    qd = QuantileDigest.create_with_hashing(5)
    assert repr(qd) == (
        "<QuantileDigest (compression: 5, "
        "range: [0, 4294967295], with_hashing: on, "
        "length: 0)>")


def test_add_without_compress():
    range_in_bits = 3
    qd = QuantileDigest(range_in_bits, 5)

    for i in range(2**range_in_bits):
        qd.add(i, False)

    assert len(qd) == 2**(range_in_bits + 1) - 1, "Incorrect number of nodes"
    assert qd.count() == 2**range_in_bits, "Invalid tree"


def test_compress():
    qd = QuantileDigest(3, 3)

    for i in range(10):
        qd.add(0)

    assert len(qd) == 4, "Incorrect number of nodes"
    assert qd.count() == 10, "Invalid counts"

    qd.compress()

    assert len(qd) == 1, "Incorrect number of nodes"
    assert qd.count() == 10, "Invalid counts"

    qd.add(7)

    assert len(qd) == 5, "Incorrect number of nodes"
    assert qd.count() == 11, "Invalid counts"

    qd.compress()

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
