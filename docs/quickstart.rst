
.. code:: python

   from pdsa.membership.bloom import BloomFilter
   
   bf = BloomFilter(1000000, 5)
   bf.add("hello")
   bf.test("hello")
