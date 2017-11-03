"""Example how to use QuantileDigest."""
import random

from pdsa.rank.qdigest import QuantileDigest

if __name__ == '__main__':
    qd = QuantileDigest(4, 5)

    random.seed(42)
    for i in range(100):
        qd.add(random.randrange(0, 16))

    qd.compress()

    print(qd)
    print("Size in bytes of the q-digest:", qd.sizeof())
    print("Total elements in the q-digest:", qd.count())

    print("50th percentile (median):", qd.quantile_query(0.5))
    print("95th percentile:", qd.quantile_query(0.95))

    print("Rank of the element <10>:", qd.inverse_quantile_query(10))

    print("Number of elements in [4, 9]:", qd.interval_query(4, 9))
