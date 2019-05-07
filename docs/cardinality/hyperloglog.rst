HyperLogLog
=============

HyperLogLog algorithm was proposed by Philippe Flajolet, Éric Fusy,
Olivier Gandouet, and Frédéric Meunier in 2007.

It's a hash-based probabilistic algorithm for counting the number of
distinct values in the presence of duplicates.


This implementation uses the classical algorithm with a 32-bit hash function
and 4-byte counters.


.. code:: python

    from pdsa.cardinality.hyperloglog import HyperLogLog

    hll = HyperLogLog(10)
    hll.add("hello")
    print(hll.count())



Build a counter
----------------

To build a counter, specify its precision - the number of bits that should be
used to randomly choose the counter (stochastic averaging). The rest of the bits
of the 32-bit hash value will be used to index into the selected counter.


.. code:: python

    from pdsa.cardinality.hyperloglog import HyperLogLog

    hll = HyperLogLog(precision=10)


.. note::

    Precision has to be an integer in range 4 ... 16.


.. note::

    This implementation uses MurmurHash3 family of hash functions
    which yields a 32-bit hash value.


Index element into the counter
------------------------------


.. code:: python

    hll.add("hello")


.. note::

   It is possible to index into the counter any elements (internally
   it uses *repr()* of the python object to calculate hash values for
   elements that are not integers, strings or bytes.



Size of the counter in bytes
----------------------------

.. code:: python

    print(hll.sizeof())


Length of the counter
---------------------

.. code:: python

    print(len(hll))


Count of unique elements in the counter
---------------------------------------

.. code:: python

    print(hll.count())


.. warning::

   It is only an approximation of the exact cardinality.
