#include "BitField.h"


const unsigned int onesInByte[256] = {
    0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,1,2,2,
    3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,
    4,5,3,4,4,5,4,5,5,6,1,2,2,3,2,3,3,4,2,
    3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,
    4,5,5,6,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,
    6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,1,2,
    2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,
    4,4,5,3,4,4,5,4,5,5,6,2,3,3,4,3,4,4,5,
    3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,
    6,5,6,6,7,2,3,3,4,3,4,4,5,3,4,4,5,4,5,
    5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,3,
    4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,4,5,5,6,
    5,6,6,7,5,6,6,7,6,7,7,8
};


/*
   Clear all bits.
*/
void BitField::clear() {
    field = 0;
}

/*
   Count number of set bits.

   The faster method is to lookup in predefined table
   for one of the possible 256 values that `field` can have.
*/
uint8_t BitField::count() {
    return onesInByte[(unsigned int)field];
}


/*
    Change bit at bit_number to the value of the flag.
*/
void BitField::set_bit(uint8_t bit_number, bool flag) {  
    field = (field & ~(1 << bit_number)) | (flag << bit_number);
}

/*
    Toggle bit at position bit_number.
*/
void BitField::toggle_bit(uint8_t bit_number) {
    field ^= 1 << bit_number;
}

/*
    Clear bit at position bit_number.
*/
void BitField::clear_bit(uint8_t bit_number) {
    field &= ~(1 << bit_number);
}

/*
    Get the value of the bit at position bit_number.
*/
bool BitField::get_bit(uint8_t bit_number) {
    return (field >> bit_number) & 1;
}
