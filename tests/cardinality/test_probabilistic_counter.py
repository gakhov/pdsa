import pytest

from pdsa.cardinality.probabilistic_counter import ProbabilisticCounter


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
    pc = ProbabilisticCounter(10)
    assert pc.sizeof() == 40, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        pc = ProbabilisticCounter(0)
    assert str(excinfo.value) == 'At least one hash function is required'


def test_repr():
    pc = ProbabilisticCounter(10)

    assert repr(pc) == (
        "<ProbabilisticCounter (length: 320, num_of_hashes: 10)>")


def test_add():
    pc = ProbabilisticCounter(10)

    for word in ["test", 1, {"hello": "world"}]:
        pc.add(word)


def test_count():
    # pc = ProbabilisticCounter(10)

    # assert pc.count() == 0

    # pc.add("test")
    # assert pc.count() == 1

    # pc.add("test")
    # assert pc.count() == 1

    # del pc

    pc = ProbabilisticCounter(2)

    for word in LOREM_TEXT["text"].split():
        pc.add(word)

    assert pc.count() == LOREM_TEXT["num_of_unique_words"]


def test_len():
    pc = ProbabilisticCounter(10)
    assert len(pc) == 320
