#include "BitCounter.h"

const uint8_t lowest = 0;  // first 4bits (0bxxxx0000)
const uint8_t highest = 1; // second 4 bits (0b0000xxxx)


/*
   Adding 2 unsigned integers using bitwise operations.
*/
uint8_t add(uint8_t summand1, uint8_t summand2) {
    uint8_t carry;
    while(summand2 != 0) {
        carry = summand1 & summand2;
        summand1 = summand1 ^ summand2;
        summand2 = carry << 1;
    }
    return summand1;
}


/*
   Reset both 4-bits counter at once.
*/
void BitCounter::reset() {
    counter = 0;
}


/*
   Reset 4-bit counter.
*/
void BitCounter::reset(uint8_t counter_number) {
    if(counter_number == highest) {
        counter &= 0b11110000;
    }
    if(counter_number == lowest) {
        counter &= 0b00001111;
    }
}

/*
    Increment 4-bit counter by 1.
*/

void BitCounter::inc(uint8_t counter_number) {
    if(counter_number == highest) {
        if ((counter & 0b00001111) != 0b00001111) {
            counter = add(counter & 0b00001111, 0b00000001);
        }
    }
    if(counter_number == lowest) {
        if ((counter & 0b11110000) != 0b11110000) {
            counter = add(counter & 0b11110000, 0b00010000);
        }
    }
}

/*
    Decrement 4-bit counter by 1.
*/

void BitCounter::dec(uint8_t counter_number) {
    if(counter_number == highest) {
        if ((counter & 0b00001111) != 0) {
            counter = (counter & 0b00001111) ^ 0b00000001;
        }
    }
    if(counter_number == lowest) {
        if ((counter & 0b11110000) != 0) {
            counter = (counter & 0b11110000) ^ 0b00010000;
        }
    }
}


/*
    Get 4-bit counter's value.
*/

uint8_t BitCounter::value(uint8_t counter_number) {
    if(counter_number == highest) {
        return counter & 0b00001111;
    }
    if(counter_number == lowest) {
        return (counter & 0b11110000) >> 4;
    }
    return 0;
}
