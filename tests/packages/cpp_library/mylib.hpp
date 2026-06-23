#pragma once

// A small C++ library, standing in for one you build yourself or pull in with
// add_subdirectory()/find_package().
class Multiplier {
public:
  explicit Multiplier(int factor);
  int compute(int value) const;

private:
  int factor_;
};
