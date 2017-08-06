#include "BitField.h"

/*
   Clear all bits.
*/
void BitField::clear() {
    field = 0;
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
