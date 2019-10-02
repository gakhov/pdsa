"""Example how to use Count Sketch."""

from pdsa.frequency.count_sketch import CountSketch


if __name__ == '__main__':

    # Count Sketch takes num_of_counters as number of counter arrays 
    # and length_of_counter as number of counters in each counter array


    # Here we check how the dimension matters:
    cs_complex = CountSketch(10, 2000) 

    for i in range(0,100): 
        cs_complex.add("Helo")

        print(cs_complex.frequency("hello"))

    # This will print 0 as we are adding a different word.

    # However if we reduce too much the dimensions the hash might be oversimplistic. 
    # See for example:
    cs_simple = CountSketch(1, 1) 

    for i in range(0,100): 
        cs_simple.add("Helo")

        print(cs_simple.frequency("hello"))

    # This will print added frequencies!

    # Be aware that the more clomplexity the larger the size!

    print("Complex method has size of {} bytes whereas simple one only {} bytes!".format(cs_complex.sizeof(), cs_simple.sizeof()))



  