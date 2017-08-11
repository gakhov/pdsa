/*
    BitCounter

    The smallest unit in C++ is a byte even if you need to encode 0/1 type.
    This is an implementation of two 4-bit counters encoded in 8bit field
    called BitCounter.

*/

#ifndef _BITCOUNTER_H_
#define _BITCOUNTER_H_

#include <stdint.h>


class BitCounter {
  private:
      uint8_t counter;
  
  public:
      BitCounter(): counter(0) {}
      ~BitCounter() {}
 
      void reset();

      void reset(uint8_t counter_number);
      void inc(uint8_t counter_number);
      void dec(uint8_t counter_number);

      uint8_t value(uint8_t counter_number);
};

#endif // _BITCOUNTER_H_
