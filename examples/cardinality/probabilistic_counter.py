"""Example how to use ProbabilisticCounter."""

from pdsa.cardinality.probabilistic_counter import ProbabilisticCounter


LOREM_IPSUM = (
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    " Mauris consequat leo ut vehicula placerat. In lacinia, nisl"
    " id maximus auctor, sem elit interdum urna, at efficitur tellus"
    " turpis at quam. Pellentesque eget iaculis turpis. Nam ac ligula"
    " ut nunc porttitor pharetra in non lorem. In purus metus,"
    " sollicitudin tristique sapien."
)

if __name__ == '__main__':
    pc = ProbabilisticCounter(256)

    print(pc)
    print("PC counter uses {} bytes in the memory".format(pc.sizeof()))

    print("Counter contains approx. {} unique elements".format(pc.count()))

    words = set(LOREM_IPSUM.split())
    for word in words:
        pc.add(word.strip(" .,"))

    print("Added {} words, in the counter approx. {} unique elements".format(
        len(words), pc.count()))
