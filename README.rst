Probabilistic Data Structures in Python
========================================

.. contents ::


Introduction
------------

Probabilistic data structures is a common name of data structures
based on different hashing techniques.

Unlike regular (or deterministic) data structures, they always give you
approximated answers and usually provide reliable ways to estimate
the error probability.

The potential losses or errors are fully compensated by extremely
low memory requirements, constant query time and scaling.

Dependencies
---------------------

* Python 3.3+ (http://python.org/download/)
* Cython 0.25+ (http://cython.org/#download)


Documentation
--------------

TODO

License
-------

MIT License


Source code
-----------

* https://github.com/gakhov/python-pds/


Authors
-------

* Maintainer: `Andrii Gakhov <andrii.gakhov@gmail.com>`


Install
--------

1. Download `python-pds` archive::

    $ git clone https://github.com/gakhov/python-pds.git
    $ cd python-pds

For other download options (zip, tarball) visit the github web page of `python-pds <https://github.com/gakhov/python-pds>`_

2. Build `python-pds` extension module::

    $ make build

3. Install `python-pds` module into your Python distribution::

    $ [sudo] make install

3. Test install::

    $ bin/python
    >>> import pds
    >>>
