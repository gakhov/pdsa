Count Sketch
================

Count Sketch is a simple space-efficient probabilistic data structure
that is used to estimate frequencies of elements in data streams and can
address the Heavy hitters problem. It was proposed by Moses Charikar, Kevin Chen, and Martin Farach-Colton in 2002.

References
----------
[1] Charikar, M., Chen, K., Farach-Colton, M.
    "Finding Frequent Items in Data Streams"
    Proceedings of the 29th International Colloquium on Automata, Languages and
    Programming, pp. 693–703, Springer, Heidelberg.
    https://www.cs.rutgers.edu/~farach/pubs/FrequentStream.pdf


This implementation uses MurmurHash3 family of hash functions
which yields a 32-bit hash value. Thus, the length of the counters
is expected to be smaller or equal to the (2^{32} - 1), since
we cannot access elements with indexes above this value.


.. code:: python

    from pdsa.frequency.count_min_sketch import CountSketch

    cs = CountSketch(5, 2000)
    cs.add("hello")
    cs.frequency("hello")



Build a sketch
----------------

You can build a new sketch either from specifiyng its dimensions
(number of counter arrays and their length), or from the expected
overestimation diviation and standard error probability.


Build filter from its dimensions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

    from pdsa.frequency.count_min_sketch import CountSketch

    cs = CountSketch(num_of_counters=5, length_of_counter=2000)


Build filter from the expected errors
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In this case the number of counter arrays and their length
will be calculated corresponsing to the expected overestimation
and the requested error.


.. code:: python

    from pdsa.frequency.count_min_sketch import CountSketch

    cs = CountSketch.create_from_expected_error(deviation=0.000001, error=0.01)


.. note::

    The `deviation` is the error ε in answering the paricular query.
    For example, if we expect 10^7 elements and allow the fixed
    overestimate of 10, the deviation is 10/10^7 = 10^{-6}.

    The `error` is the standard error δ (0 < error < 1).


.. note::

    The Count–Min Sketch is approximate and probabilistic at the same
    time, therefore two parameters, the error ε in answering the paricular
    query and the error probability δ, affect the space and time
    requirements. In fact, it provides the guarantee that the estimation
    error for frequencies will not exceed ε x n
    with probability at least 1 – δ.


Index element into the sketch
------------------------------


.. code:: python

    cs.add("hello")


.. note::

   It is possible to index into the counter any elements (internally
   it uses *repr()* of the python object to calculate hash values for
   elements that are not integers, strings or bytes.


Estmiate frequency of the element
---------------------------------------

.. code:: python

    print(cs.frequency("hello"))


.. warning::

   It is only an approximation of the exact frequency.



Size of the sketch in bytes
----------------------------

.. code:: python

    print(cs.sizeof())


Length of the sketch
---------------------

.. code:: python

    print(len(cs))
