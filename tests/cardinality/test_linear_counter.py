import pytest

from pdsa.cardinality.linear_counter import LinearCounter

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
    lc = LinearCounter(8000)
    assert lc.sizeof() == 1000, "Unexpected size in bytes"

    with pytest.raises(ValueError) as excinfo:
        lc = LinearCounter(0)
    assert str(excinfo.value) == 'Counter length can\'t be 0 or negative'


def test_repr():
    lc = LinearCounter(8000)

    assert repr(lc) == "<LinearCounter (length: 8000)>"


def test_add():
    lc = LinearCounter(8000)

    for word in ["test", 1, {"hello": "world"}]:
        lc.add(word)


def test_count():
    lc = LinearCounter(100000)

    assert lc.count() == 0

    lc.add("test")
    assert lc.count() == 1

    lc.add("test")
    assert lc.count() == 1

    lc.add("test2")
    assert lc.count() == 2

    del lc

    lc = LinearCounter(100000)

    for word in LOREM_TEXT["text"].split():
        lc.add(word)

    assert lc.count() == LOREM_TEXT["num_of_unique_words"]


def test_len():
    lc = LinearCounter(8000)
    assert len(lc) == 8000

    lc = LinearCounter(8001)
    assert len(lc) == 8008
