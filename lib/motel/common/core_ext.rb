# Motel Core Extensions
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

class Float
  # Round float to the specified precision
  #
  # @param [Integer] precision number of decimal places to return in float
  # @return float rounded to the specified precision
  def round_to(precision)
     raise ArgumentError, precision if precision < 0
     return (self * 10 ** precision).round.to_f / (10 ** precision)
  end
end

class Fixnum
  # Returns self (fixnums are always rounded)
  def round_to(precision)
    return self
  end

  # return the number of zeros after the first non-zero least significant digit
  def zeros
    return 1 if self == 0

    v = self.abs
    i = -1
    until v < 1
      z  = v % 10 == 0
      v /= 10
      i += 1
      return i unless z
    end
    i
  end

  # return the number of significant digits
  def digits
    v = self.abs
    i = 0
    until v < 1
      v /= 10
      i += 1
    end

    i
  end
end
