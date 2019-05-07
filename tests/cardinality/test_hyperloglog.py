import pytest

from math import sqrt
from pdsa.cardinality.hyperloglog import HyperLogLog


LOREM_TEXT = {
    "text": (
        "Lorem ipsum dolor sit amet consectetur adipiscing elit Donec quis "
        "felis at velit pharetra dictum Sed vehicula est at mi lobortis "
        "vitae suscipit mi aliquet Sed ut pharetra nisl  Donec maximus enim "
        "sit amet erat ullamcorper ut mattis mauris gravida Nulla sagittis "
        "quam a arcu pretium iaculis Donec vestibulum tellus nec ligula "
        "mattis vitae aliquam augue dapibus Curabitur pulvinar elit nec "
        "blandit pharetra ipsum elit ultrices sem et bibendum lorem arcu "
        "sit amet arcu Nam pulvinar porta molestie Integer posuere ipsum "
        "venenatis velit euismod accumsan sed quis nibh Suspendisse libero "
        "odio tempor ultricies lectus non volutpat rutrum diam Nullam et "
        "sem eu quam sodales vulputate Nulla condimentum blandit mi ac "
        "varius quam vehicula id Quisque sit amet molestie lacus ac "
        "efficitur ante Proin orci lacus fringilla nec eleifend non "
        "maximus vel ipsum Sed luctus enim tortor cursus semper mauris "
        "ultrices vel Vivamus eros purus sodales sed lectus at accumsan "
        "dictum massa Integer pulvinar tortor sagittis tincidunt risus "
        "non ultricies augue Aenean efficitur justo orci at semper ipsum "
        "efficitur ut Phasellus tincidunt nibh ut eros bibendum eleifend "
        "Donec porta risus nec placerat viverra leo justo sollicitudin "
        "metus a lacinia mi justo ut augue Duis dolor lacus sodales ut "
        "tortor eu rutrum"
    ),
    "num_of_words": 200,
    "num_of_unique_words": 111,
    "num_of_unique_words_icase": 109
}


def test_init():
    hll = HyperLogLog(10)
    assert hll.sizeof() == 4096, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        hll = HyperLogLog(2)
    assert str(excinfo.value) == (
        "Precision has to be in range 4...16")


def test_repr():
    hll = HyperLogLog(6)

    assert repr(hll) == (
        "<HyperLogLog (length: 64, precision: 6)>")


def test_add():
    hll = HyperLogLog(10)

    for word in ["test", 1, {"hello": "world"}]:
        hll.add(word)


def test_count():
    precision = 6
    hll = HyperLogLog(precision)
    std = 1.04 / sqrt(1 << precision)

    assert hll.count() == 0

    boost = 50 * LOREM_TEXT["num_of_unique_words"]
    num_of_unique_words = boost * LOREM_TEXT["num_of_unique_words"]

    for i in range(boost):
        for word in LOREM_TEXT["text"].split():
            hll.add("{}_{}".format(word, i))

    cardinality = hll.count()
    assert cardinality >= (1 - 2 * std) * num_of_unique_words
    assert cardinality <= (1 + 2 * std) * num_of_unique_words


def test_count_large():
    precision = 6
    hll = HyperLogLog(precision)

    # NOTE: make n larger than the HLL upper correction threshold
    boost = 143165576 // LOREM_TEXT["num_of_unique_words"] + 1
    num_of_unique_words = boost * LOREM_TEXT["num_of_unique_words"]

    for i in range(boost):
        for word in LOREM_TEXT["text"].split():
            hll.add("{}_{}".format(word, i))

    cardinality = hll.count()
    assert cardinality >= 0.7 * num_of_unique_words
    assert cardinality <= 1.3 * num_of_unique_words


def test_count_small():
    precision = 6
    hll = HyperLogLog(precision)
    std = 1.04 / sqrt(1 << precision)

    short = LOREM_TEXT["text"].split()[:100]
    num_of_unique_words = len(set(short))

    for word in short:
        hll.add(word)

    cardinality = hll.count()
    assert cardinality >= (1 - 2 * std) * num_of_unique_words
    assert cardinality <= (1 + 2 * std) * num_of_unique_words


def test_len():
    hll = HyperLogLog(4)
    assert len(hll) == 16
