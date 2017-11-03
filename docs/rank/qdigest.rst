Quantile Digest (q-digest)
============================

Quantile Digest, or q-digest, is a tree-based stream summary algorithm
that was proposed by Nisheeth Shrivastava, Subhash Suri et al. in
2004 in the context of monitoring distributed data
from sensors.


.. code:: python

    from pdsa.rank.qdigest import QuantileDigest

    qd = QuantileDigest(3, 5)
    for i in range(100):
        qd.add(random.randrange(0, 8))
    qd.compress()

    qd.quantile_query(0.5)
    qd.inverse_quantile_query(5)
    qd.interval_query(2, 6)


Build a q-digest
----------------

Quantile Digest is designed to be built on integer numbers from a known range.

The range of the supported integers is defined by the number of bytes in thier
maximal representation. Thus, for k-bytes integers, the range will
be [0, 2^k - 1].

.. code:: python

   from pdsa.rank.qdigest import QuantileDigest

   qd = QuantileDigest(3, 5)


.. note::

   The ranges up to 32 bytes only are supported in the current implementation.


Add element into q-digest
-----------------------------


.. code:: python

    qd.add(5)


Quantile Query
---------------

Given a fraction ``q`` from [0, 1], the quantile query
is about to find the value whose rank in a sorted sequence
of the ``n`` values is ``q * n``.


.. code:: python

    qd.quantile_query(0.95)


Inverse Quantile Query
-----------------------

Given an element, the inverse quantile query
is about to find its rank in sorted sequence of values.

.. code:: python

    qd.inverse_quantile_query(4)


Interval (range) Query
-----------------------

Given a value the interval (range) query
is about to find the number of elements in the given range
in the sequence of elements.

.. code:: python

    qd.interval_query(3, 6)


Merge q-digests
----------------

.. code:: python

    qd1.merge(qd2)


.. warning::

   Only q-digets with same compression_factor and range are possible to merge correctly.



Length of the q-digest
----------------------

Length of the q-digest is the number of buckets (nodes) included into the q-digest.


.. code:: python

    print(len(qd))


Size of the q-digest in bytes
------------------------------

.. code:: python

    print(qd.sizeof())


.. warning::

    Since we can't calculate exact size of a dict in Cython,
    this function return some estimation based an ideal size of
    keys, values of each bucket.


Count of elements in the q-digest
---------------------------------------

.. code:: python

    print(qd.count())


.. warning::

    While we can't say exactly which elements are in the q-digest,
    (because the compression is a lossy operation), it's still
    possible to say how many in total elements were added.
