/*
    BitField

    The smallest unit in C++ is a byte even if you need to encode 0/1 type.
    In this implementation we just use every bit from such byte separately
    to encode more information.
*/

#ifndef _BITFIELD_H_
#define _BITFIELD_H_

#include <stdint.h>


class BitField {
  private:
      uint8_t field;
  
  public:
      BitField(): field(0) {}
      ~BitField() {}

      void clear();
      uint8_t count();

      void set_bit(uint8_t bit_number, bool flag);
      void toggle_bit(uint8_t bit_number);
      void clear_bit(uint8_t bit_number);
      bool get_bit(uint8_t bit_number);
};

#endif // _BITFIELD_H_
