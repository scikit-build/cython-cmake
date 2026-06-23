#include "mylib.hpp"

Multiplier::Multiplier(int factor) : factor_(factor) {}

int Multiplier::compute(int value) const { return factor_ * value; }
