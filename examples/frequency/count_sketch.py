"""Example how to use Count Sketch."""

from pdsa.frequency.count_sketch import CountSketch


VIVAMUS_ID = (
"""Vivamus id ante a odio finibus commodo. 
Integer nisi odio, volutpat et ultrices non, imperdiet ut tellus. 
Fusce dictum nulla nisl. Fusce faucibus, ipsum sed ultricies gravida, velit nunc tincidunt quam, ac efficitur orci massa sed sem.
Mauris dictum tellus est, vel varius metus fermentum sed. Phasellus et arcu eget."
"""
)

if __name__ == '__main__':
    cs = CountSketch(5, 2000) 

    print(cs)
    print("Count Sketch uses {} bytes in the memory".format(cs.sizeof()))

    print("Counter contains approx. {} unique elements".format(cs.count()))

    words = set(VIVAMUS_ID.split())
    for word in words:
        cs.add(word.strip(" .,"))

    print("Added {} words, in the counter approx. {} unique elements".format(
        len(words), cs.count()))


    """ Here we check how the dimension matters: """
    cs_complex = CountSketch(10, 2000) 

    for i in range(0,100): 
        cs_complex.add("Helo")

        print(cs_complex.frequency("hello"))

    """ This will print 0 as we are adding a different word. """

    """ However, if we reduce too much the dimensions the hash might be too simplistic. """
    cs_simple = CountSketch(1, 1) 

    for i in range(0,100): 
        cs_simple.add("Helo")

        print(cs_simple.frequency("hello"))

    """ This will print added frequencies when they are actually different words. """

    """ Be aware that the more clomplexity the larger the size! """

    print("Complex method has a size of {} bytes whereas simple has one only {} bytes!".format(cs_complex.sizeof(), cs_simple.sizeof()))



  