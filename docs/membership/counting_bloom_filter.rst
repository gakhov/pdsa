Counting Bloom Filter
======================

This implementation uses 4-bit counter implementation to store counts
of elements and bitvector to store the bloom filter array.


.. code:: python

   from pdsa.membership.bloom import CountingBloomFilter

   bf = CountingBloomFilter(1000000, 5)
   bf.add("hello")
   bf.test("hello")
   bf.remove("hello")



Build a filter
----------------

You can build a new filter either from specifiyng its length and
number of hash functions, or from the expected capacity and error
probability.


Build filter from its length
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

   from pdsa.membership.bloom import CountingBloomFilter

   bf = CountingBloomFilter(100000, 5)


.. note::

   Memory for the filter is assigned by chunks, therefore the
   length of the filter can be rounded up to use it in full.



Build filter from expected capacity
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In this case length of the filter and number of hash functions
will be calculated to handle the requested number of elements
with the requested error.


.. code:: python

   from pdsa.membership.bloom import CountingBloomFilter

   bf = CountingBloomFilter().create_from_capacity(10000, 0.02)


Add element into the filter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.. code:: python

    bf.add("hello")


.. note::

   It is possible to add into the filter any elements (internally
   it uses *repr()* of the python object to calculate hash values for
   elements that are not integers, strings or bytes.



Test if element is in the filter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

    bf.test("hello") == 1


Delete element from the filter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

    bf.remove("hello")


.. warning::

   The implementation uses 4-bit counters that freeze at value 15.
   So, the deletion, in fact, is a probabilistically correct only.



Size of the filter in bytes
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

    print(bf.sizeof())


Length of the filter
~~~~~~~~~~~~~~~~~~~~

.. code:: python

    print(len(bf))


Count of unique elements in the filter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

    print(bf.count())


.. warning::

   It is only an approximation, since there is no reliable way to
   determine the number of unique elements that are already in the filter.
