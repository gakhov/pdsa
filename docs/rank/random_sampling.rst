Random Sampling
===============

The Random sampling algorithm, often referred to as MRL, was
published by Gurmeet Singh Manku, Sridhar Rajagopalan, and Bruce
Lindsay in 1999 and addressed the problem of the correct
sampling and quantile estimation. It consists of the non-uniform
sampling technique and deterministic quantile finding algorithm.

This implementation of the simpler version of the MRL algorithm
that was proposed by Ge Luo, Lu Wang, Ke Yi, and Graham Cormode
in 2013, and denoted in the original articles as Random.


.. code:: python

    from pdsa.rank.random_sampling import RandomSampling

    rs = RandomSampling(5, 5, 7)
    for i in range(100):
        rs.add(random.randrange(0, 8))
    rs.compress()

    rs.quantile_query(0.5)
    rs.inverse_quantile_query(5)
    rs.interval_query(2, 6)


Build random sampling data structure
-------------------------------------

RandomSampling is designed to be built by specifying number of buffers,
their capacity and the maximal height (depth) of the data structure.

.. code:: python

   from pdsa.rank.random_sampling import RandomSampling

   rs = RandomSampling(5, 5, 7)

Build random sampling data structure from the expected error probability
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In this case length of the number of buffers, their capacity and
the maximal height will be calculated to support the requested error.


.. code:: python

   from pdsa.rank.random_sampling import RandomSampling

   rs = RandomSampling.create_from_error(0.01)


Add element into RandomSampling
--------------------------------


.. code:: python

    rs.add(5)


Quantile Query
---------------

Given a fraction ``q`` from [0, 1], the quantile query
is about to find the value whose rank in a sorted sequence
of the ``n`` values is ``q * n``.


.. code:: python

    rs.quantile_query(0.95)


Inverse Quantile Query
-----------------------

Given an element, the inverse quantile query
is about to find its rank in sorted sequence of values.

.. code:: python

    rs.inverse_quantile_query(4)


Interval (range) Query
-----------------------

Given a value the interval (range) query
is about to find the number of elements in the given range
in the sequence of elements.

.. code:: python

    rs.interval_query(3, 6)


Number of buffers in the data structure
----------------------------------------

The number of buffers allocated in the data structure.


.. code:: python

    print(len(rs))


Size of the data structure in bytes
-------------------------------------

.. code:: python

    print(rs.sizeof())


.. warning::

    Since we do not want to calculate exact size,
    this function return some estimation.


Number of processed elements
---------------------------------------

.. code:: python

    print(rs.count())
