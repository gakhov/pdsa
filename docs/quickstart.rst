
.. code:: python

    from pdsa.membership.bloom import BloomFilter

    bf = BloomFilter(80000, 4)

    print(bf)
    print("Bloom filter uses {} bytes in the memory".format(bf.sizeof()))

    print("Filter contains approximately {} elements".format(bf.count()))

    print("'Lorem' {} in the filter".format(
        "is" if bf.test("Lorem") else "is not"))

    words = set(LOREM_IPSUM.split())
    for word in words:
        bf.add(word.strip(" .,"))

    print("Added {} words, in the filter approximately {} elements".format(
        len(words), bf.count()))

    print("'Lorem' {} in the filter".format(
        "is" if bf.test("Lorem") else "is not"))
