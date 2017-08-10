import pytest

from pdsa.helpers.hashing.mmh import mmh3_x86_32bit


def test_int():
    assert mmh3_x86_32bit(1024, 42) == 1170829763


def test_string():
    assert mmh3_x86_32bit("test", 42) == 1956065189
    assert mmh3_x86_32bit("test", 42) != mmh3_x86_32bit(b"test", 42)


def test_bytes():
    assert mmh3_x86_32bit(b"test", 42) == 3959873882


def test_arbitrary():
    class X(object):
        def __repr__(self):
            return "X<>"

    assert mmh3_x86_32bit(X(), 42) == mmh3_x86_32bit("X<>".encode("utf-8"), 42)


def test_seed():
    assert mmh3_x86_32bit("hello", 73) != mmh3_x86_32bit("hello", 42)
    assert mmh3_x86_32bit("hello", 42) == mmh3_x86_32bit("hello", 42)
    assert mmh3_x86_32bit("hello", 42) == mmh3_x86_32bit("hello")
