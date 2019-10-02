"""Example how to use Count Sketch."""

from pdsa.frequency.count_sketch import CountSketch

DATASET = [
    30, 19, 4, 29, 9, 9, 2, 26, 12, 13, 27, 18, 3, 20, 13, 17, 24, 24, 9, 28,
    20, 30, 10, 5, 8, 2, 6, 28, 20, 17, 26, 23, 25, 26, 1, 30, 28, 20, 7, 26,
    14, 3, 21, 2, 23, 22, 4, 15, 27, 9, 19, 29, 25, 27, 25, 28, 2, 27, 29, 16,
    9, 23, 3, 30, 1, 1, 26, 6, 4, 27, 12, 13, 3, 28, 27, 10, 9, 10, 2, 22, 6,
    8, 5, 30, 21, 9, 29, 6, 5, 2, 3, 1, 16, 17, 15, 5, 3, 6, 9, 12,
]

if __name__ == '__main__':
    cs = CountSketch(5, 2000)

    print(cs)
    print("CS uses {} bytes in the memory".format(cs.sizeof()))

    for digit in DATASET:
        cs.add(digit)

    for digit in sorted(set(DATASET)):
        print("Element: {}. Freq.: {}, Est. Freq.: {}".format(
            digit, DATASET.count(digit), cs.frequency(digit)
        ))


""" Text example """

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
    cs_complex = CountSketch(5, 2000) 

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



  