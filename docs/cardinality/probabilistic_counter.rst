Probabilistic Counter
======================

Probabilistic Counting algorithm with stochastic averaging
(Flajolet-Martin algorithm) was proposed by Philippe Flajolet
and G. Nigel Martin in 1985.

It's a hash-based probabilistic algorithm for counting the number of
distinct values in the presence of duplicates.


This implementation stores number of 32-bit single counters (FM Sketches)
consequently in a single bitvector.


.. code:: python

    from pdsa.cardinality.probabilistic_counter import ProbabilisticCounter

    pc = ProbabilisticCounter(256)
    pc.add("hello")
    print(pc.count())



Build a counter
----------------

To build a counter, specify its length.


.. code:: python

    from pdsa.cardinality.probabilistic_counter import ProbabilisticCounter

    pc = ProbabilisticCounter(number_of_counters=256)


.. note::

    Memory for the counter is assigned by chunks, therefore the
    length of the counter can be rounded up to use it in full.


.. note::

    This implementation uses MurmurHash3 family of hash functions
    which yields a 32-bit hash value that implies the maximal length
    of the counter.

.. note::

    The Algorithm has been developed for large cardinalities when
    ratio ``card()/num_of_counters > 10-20``, therefore a special correction
    required if low cardinality cases has to be supported. In this implementation
    we use correction proposed by Scheuermann and Mauve (2007).

    .. code:: python

        from pdsa.cardinality.probabilistic_counter import ProbabilisticCounter

        pc = ProbabilisticCounter(
            numbder_of_counters=256,
            with_small_cardinality_correction=True)



Index element into the counter
------------------------------


.. code:: python

    pc.add("hello")


.. note::

   It is possible to index into the counter any elements (internally
   it uses *repr()* of the python object to calculate hash values for
   elements that are not integers, strings or bytes.



Size of the counter in bytes
----------------------------

.. code:: python

    print(pc.sizeof())


Length of the counter
---------------------

.. code:: python

    print(len(pc))


Count of unique elements in the counter
---------------------------------------

.. code:: python

    print(pc.count())


.. warning::

   It is only an approximation of the exact cardinality.
