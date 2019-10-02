Count-Min Sketch
================

Count–Min Sketch is a simple space-efficient probabilistic data structure
that is used to estimate frequencies of elements in data streams and can
address the Heavy hitters problem. It was presented in 2003 [1] by
Graham Cormode and Shan Muthukrishnan and published in 2005 [2].

References
----------
[1] Cormode, G., Muthukrishnan, S.
    "What's hot and what's not: Tracking most frequent items dynamically"
    Proceedings of the 22th ACM SIGMOD-SIGACT-SIGART symposium on Principles
    of database systems, San Diego, California - June 09-11, 2003,
    pp. 296–306, ACM New York, NY.
    http://www.cs.princeton.edu/courses/archive/spr04/cos598B/bib/CormodeM-hot.pdf
[2] Cormode, G., Muthukrishnan, S.
    "An Improved Data Stream Summary: The Count–Min Sketch and its Applications"
    Journal of Algorithms, Vol. 55 (1), pp. 58–75.
    http://dimacs.rutgers.edu/~graham/pubs/papers/cm-full.pdf


This implementation uses MurmurHash3 family of hash functions
which yields a 32-bit hash value. Thus, the length of the counters
is expected to be smaller or equal to the (2^{32} - 1), since
we cannot access elements with indexes above this value.


.. code:: python

    from pdsa.frequency.count_min_sketch import CountMinSketch

    cms = CountMinSketch(5, 2000)
    cms.add("hello")
    cms.frequency("hello")



Build a sketch
----------------

You can build a new sketch either from specifiyng its dimensions
(number of counter arrays and their length), or from the expected
overestimation diviation and standard error probability.


Build filter from its dimensions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: python

    from pdsa.frequency.count_min_sketch import CountMinSketch

    cms = CountMinSketch(num_of_counters=5, length_of_counter=2000)


Build filter from the expected errors
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In this case the number of counter arrays and their length
will be calculated corresponsing to the expected overestimation
and the requested error.


.. code:: python

    from pdsa.frequency.count_min_sketch import CountMinSketch

    cms = CountMinSketch.create_from_expected_error(deviation=0.000001, error=0.01)


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

    cms.add("hello")


.. note::

   It is possible to index into the counter any elements (internally
   it uses *repr()* of the python object to calculate hash values for
   elements that are not integers, strings or bytes.


Estmiate frequency of the element
---------------------------------------

.. code:: python

    print(cms.frequency("hello"))


.. warning::

   It is only an approximation of the exact frequency.



Size of the sketch in bytes
----------------------------

.. code:: python

    print(cms.sizeof())


Length of the sketch
---------------------

.. code:: python

    print(len(cms))
