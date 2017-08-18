"""Example how to use Linear Counter."""

from pdsa.cardinality.linear_counter import LinearCounter


LOREM_IPSUM = (
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    " Mauris consequat leo ut vehicula placerat. In lacinia, nisl"
    " id maximus auctor, sem elit interdum urna, at efficitur tellus"
    " turpis at quam. Pellentesque eget iaculis turpis. Nam ac ligula"
    " ut nunc porttitor pharetra in non lorem. In purus metus,"
    " sollicitudin tristique sapien."
)

if __name__ == '__main__':
    lc = LinearCounter(10000)

    print(lc)
    print("Linear counter uses {} bytes in the memory".format(lc.sizeof()))

    print("Counter contains approx. {} unique elements".format(lc.count()))

    words = set(LOREM_IPSUM.split())
    for word in words:
        lc.add(word.strip(" .,"))

    print("Added {} words, in the counter approx. {} unique elements".format(
        len(words), lc.count()))
