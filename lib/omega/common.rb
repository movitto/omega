# Utility Methods
#
# Copyright (C) 2011-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

class Object
  def numeric?
    Float(self) != nil rescue false
  end

  def attr_from_args(args, params = {})
    params.keys.each { |p|
      getter = "#{p}".intern
      setter = "#{p}=".intern
      if args.has_key?(p)
        self.send(setter, args[p])

      elsif args.has_key?(p.to_s)
        self.send(setter, args[p.to_s])

      else
        v = self.send(getter)
        self.send(setter, v || params[p])

      end
    }
  end

  def update_from(old, *attrs)
    attrs.each { |attr|
      getter = attr.intern
      setter = "#{attr}=".intern
      v  = old.send(getter)
      self.send(setter, v) unless v.nil?
    }
  end
end

class Array
  def uniq_by(&blk)
    transforms = {}
    select do |el|
      t = blk[el]
      should_keep = !transforms[t]
      transforms[t] = true
      should_keep
    end
  end
end
