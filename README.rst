PDSA: Probabilistic Data Structures and Algorithms in Python
************************************************************

.. image:: https://img.shields.io/travis/gakhov/pdsa/master.svg?style=flat-square
    :target: https://travis-ci.org/gakhov/pdsa
    :alt: Travis Build Status

.. image:: https://img.shields.io/github/release/gakhov/pdsa/all.svg?style=flat-square
    :target: https://github.com/gakhov/pdsa/releases
    :alt: Current Release Version

.. image:: https://img.shields.io/pypi/v/pdsa.svg?style=flat-square
    :target: https://pypi.python.org/pypi/pdsa
    :alt: pypi Version

.. image:: https://readthedocs.org/projects/pdsa/badge/?version=latest&style=flat-square
    :target: http://pdsa.readthedocs.io/en/latest/
    :alt: Documentation Version

.. image:: https://img.shields.io/pypi/pyversions/pdsa.svg?style=flat-square
    :target: https://github.com/gakhov/pdsa
    :alt: Python versions



.. contents ::

The Book
----------

Everybody interested in learning more about probabilistic data structures and
algorithms could be referred to our recently published book:

`Probabilistic Data Structures and Algorithms for Big Data Applications <https://pdsa.gakhov.com>`_ by Andrii Gakhov

2019, ISBN: 978-3748190486 (paperback) ASIN: B07MYKTY8W (e-book)


Introduction
------------

Probabilistic data structures is a common name of data structures
based on different hashing techniques.

Unlike regular (or deterministic) data structures, they always provide
approximated answers, but usually with reliable ways to estimate
the error probability.

The potential losses or errors are fully compensated by extremely
low memory requirements, constant query time and scaling.

GitHub repository: `<https://github.com/gakhov/pdsa>`_


Dependencies
---------------------

* Python 3.5+ (http://python.org/download/)
* Cython 0.28+ (http://cython.org/#download)


Documentation
--------------

The latest documentation can be found at `<http://pdsa.readthedocs.io/en/latest/>`_


**Membership problem**

- `Bloom Filter <http://pdsa.readthedocs.io/en/latest/membership/bloom_filter.html>`_
- `Counting Bloom Filter <http://pdsa.readthedocs.io/en/latest/membership/counting_bloom_filter.html>`_

**Cardinality problem**

- `Linear counter <http://pdsa.readthedocs.io/en/latest/cardinality/linear_counter.html>`_
- `Probabilistic counter (Flajolet–Martin algorithm) <http://pdsa.readthedocs.io/en/latest/cardinality/probabilistic_counter.html>`_
- `HyperLogLog <http://pdsa.readthedocs.io/en/latest/cardinality/hyperloglog.html>`_

**Rank problem**

- `q-digest <http://pdsa.readthedocs.io/en/latest/rank/qdigest.html>`_


License
-------

MIT License


Source code
-----------

* https://github.com/gakhov/pdsa/


Authors
-------

* Maintainer: `Andrii Gakhov <andrii.gakhov@gmail.com>`


Install with pip
--------------------

Installation requires a working build environment.

Using pip, PDSA releases are currently only available as source packages.

.. code:: bash

    $ pip3 install -U pdsa

When using pip it is generally recommended to install packages in a ``virtualenv``
to avoid modifying system state:

.. code:: bash

    $ virtualenv .env -p python3 --no-site-packages
    $ source .env/bin/activate
    $ pip3 install -U cython
    $ pip3 install -U pdsa


Compile from source
---------------------

The other way to install PDSA is to clone its
`GitHub repository <https://github.com/gakhov/pdsa>`_ and build it from
source.

.. code:: bash

    $ git clone https://github.com/gakhov/pdsa.git
    $ cd pdsa

    $ make install

    $ bin/pip3 install -r requirements-dev.txt
    $ make test
