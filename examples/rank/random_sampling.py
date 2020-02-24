"""Example how to use RandomSampling."""
import random

from pdsa.rank.random_sampling import RandomSampling

if __name__ == '__main__':
    rs = RandomSampling(16, 5, 3)

    random.seed(42)
    for i in range(100):
        rs.add(random.randrange(0, 16))

    rs.compress()

    print(rs)
    print("Size in bytes of the sketch:", rs.sizeof())
    print("Total elements in the sketch:", rs.count())

    print("50th percentile (median):", rs.quantile_query(0.5))
    print("95th percentile:", rs.quantile_query(0.95))

    print("Rank of the element <10>:", rs.inverse_quantile_query(10))

    print("Number of elements in [4, 9]:", rs.interval_query(4, 9))