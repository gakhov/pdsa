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
          