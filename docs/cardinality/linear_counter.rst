Linear Counter
======================

A Linear-Time probabilistic counting algorithm, or Linear Counting algorithm,
was proposed by Kyu-Young Whang at al. in 1990.

It's a hash-based probabilistic algorithm for counting the number of
distinct values in the presence of duplicates.

The algorithm has O(N) time complexity, where N is the total number of elements,
including duplicates.


This implementation uses bitvector to store the counter's array.


.. code:: python

    from pdsa.cardinality.linear_counter import LinearCounter

    lc = LinearCounter(1000000)
    lc.add("hello")
    print(lc.count())



Build a counter
----------------

To build a counter, specify its length.


.. code:: python

    from pdsa.cardinality.linear_counter import LinearCounter

    lc = LinearCounter(100000)


.. note::

   Memory for the counter is assigned by chunks, therefore the
   length of the counter can be rounded up to use it in full.


.. note::

    This implementation uses MurmurHash3 family of hash functions
    which yields a 32-bit hash value that implies the maximal length
    of the counter.



Index element into the counter
------------------------------


.. code:: python

    lc.add("hello")


.. note::

   It is possible to index into the counter any elements (internally
   it uses *repr()* of the python object to calculate hash values for
   elements that are not integers, strings or bytes.



Size of the counter in bytes
----------------------------

.. code:: python

    print(lc.sizeof())


Length of the counter
---------------------

.. code:: python

    print(len(lc))


Count of unique elements in the counter
---------------------------------------

.. code:: python

    print(lc.count())


.. warning::

   It is only an approximation, that is quite good for not huge cardinalities.
