import pytest

from pdsa.rank.qdigest import QuantileDigest


def test_init():
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

    # for i in range(6):
    #     qd.add(0)

    # for i in range(1):
    #     qd.add(1)

    # for i in range(3):
    #     qd.add(2)

    # for i in range(5):
    #     qd.add(3)

    # for i in range(1):
    #     qd.add(4)

    # for i in range(2):
    #     qd.add(5)

    # for i in range(1):
    #     qd.add(6)

    print(qd.debug())
    print(qd.compress())


    for i in range(1):
        qd.add(0)
    print(qd.debug())
    print(qd.compress())
    raise
