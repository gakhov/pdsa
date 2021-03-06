"""Example how to use Counting Bloom Filter."""

from pdsa.membership.counting_bloom_filter import CountingBloomFilter


LOREM_IPSUM = (
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    " Mauris consequat leo ut vehicula placerat. In lacinia, nisl"
    " id maximus auctor, sem elit interdum urna, at efficitur tellus"
    " turpis at quam. Pellentesque eget iaculis turpis. Nam ac ligula"
    " ut nunc porttitor pharetra in non lorem. In purus metus,"
    " sollicitudin tristique sapien."
)

if __name__ == '__main__':
    bf = CountingBloomFilter(80000, 4)

    print(bf)
    print("Bloom filter uses {} bytes in the memory".format(bf.sizeof()))

    print("Filter contains approx. {} unique elements".format(bf.count()))

    print("'Lorem' {} in the filter".format(
        "is" if bf.test("Lorem") else "is not"))

    words = set(LOREM_IPSUM.split())
    for word in words:
        bf.add(word.strip(" .,"))

    print("Added {} words, in the filter approx. {} unique elements".format(
        len(words), bf.count()))

    print("'Lorem' {} in the filter".format(
        "is" if bf.test("Lorem") else "is not"))

    print("Delete 'Lorem' from the filter")
    bf.remove("Lorem")

    print("In the filter approximately {} elements".format(bf.count()))
    print("'Lorem' {} in the filter".format(
        "is" if bf.test("Lorem") else "is not"))
