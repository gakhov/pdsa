"""Example how to use HyperLogLog."""

from pdsa.cardinality.hyperloglog import HyperLogLog


LOREM_IPSUM = (
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    " Mauris consequat leo ut vehicula placerat. In lacinia, nisl"
    " id maximus auctor, sem elit interdum urna, at efficitur tellus"
    " turpis at quam. Pellentesque eget iaculis turpis. Nam ac ligula"
    " ut nunc porttitor pharetra in non lorem. In purus metus,"
    " sollicitudin tristique sapien."
)

if __name__ == '__main__':
    hll = HyperLogLog(10)

    print(hll)
    print("HLL counter uses {} bytes in the memory".format(hll.sizeof()))

    print("Counter contains approx. {} unique elements".format(hll.count()))

    words = set(LOREM_IPSUM.split())
    for word in words:
        hll.add(word.strip(" .,"))

    print("Added {} words, in the counter approx. {} unique elements".format(
        len(words), hll.count()))
