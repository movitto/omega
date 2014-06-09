# Omega ConstrainedAttributes Spec
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/constraints'

module Omega

class ConstrainedAttributeTest
  extend  ConstrainedAttributes
  include ConstrainedAttributes
end

describe ConstrainedAttributes do
  describe "#explicity_set!" do
    it "sets attribute to value" do
      t = ConstrainedAttributeTest.new
      t.explicitly_set!('foobar', 111)
      t.instance_variable_get("@foobar").should == 111

      t = ConstrainedAttributeTest.new
      t.explicitly_set!(:foobar, 111)
      t.instance_variable_get("@foobar").should == 111
    end

    it "sets set_attr flag" do
      t = ConstrainedAttributeTest.new
      t.explicitly_set!(:foobar, 111)
      t.instance_variable_get("@foobar").should be_true
    end
  end

  describe "#explicity_set?" do
    it "returns value of set_attr flag" do
      t = ConstrainedAttributeTest.new
      t.instance_variable_set("@set_foobar", true)
      t.explicitly_set?("foobar").should be_true
    end
  end

  describe "#explicit_value" do
    it "returns value of attribute" do
      t = ConstrainedAttributeTest.new
      t.instance_variable_set("@foobar", 'barfoo')
      t.explicit_value('foobar').should == 'barfoo'
      t.explicit_value(:foobar).should == 'barfoo'
    end
  end

  describe "#constraint_owner" do
    context "of instance of class with constrained attributes" do
      it "returns class" do
        t = ConstrainedAttributeTest.new
        t.constraint_owner.should == ConstrainedAttributeTest
      end
    end

    context "of class with constrained attributes" do
      it "returns self" do
        ConstrainedAttributeTest.constraint_owner.should ==
          ConstrainedAttributeTest
      end
    end
  end

  describe "::constraint_domain" do
    before(:each) do
      @orig_domain = ConstrainedAttributeTest.constraint_domain
    end

    after(:each) do
      ConstrainedAttributeTest.constraint_domain @orig_domain
    end

    it "gets/sets constraint domain" do
      ConstrainedAttributeTest.constraint_domain 'foobar'
      ConstrainedAttributeTest.constraint_domain.should == 'foobar'
    end

    context "no constraint domain set" do
      it "sets domain from demodulized class name" do
        ConstrainedAttributeTest.constraint_domain.should ==
          'constrainedattributetest'
      end
    end
  end

  describe "::get_constraint" do
    it "returns specified omega constraint" do
      Omega::Constraints.should_receive(:get).
                         with('constraint').and_return('val')
      ConstrainedAttributeTest.get_constraint('constraint').should == 'val'
    end

    context "specified omega constraint not found" do
      it "prepends constraint domain and retries lookup" do
        Omega::Constraints.should_receive(:get).
                           with('constraint').and_return(nil)
        ConstrainedAttributeTest.should_receive(:constraint_domain).
                                 and_return('domain')
        Omega::Constraints.should_receive(:get).
                           with('domain', 'constraint').and_return('val')
        ConstrainedAttributeTest.get_constraint('constraint').should ==
          'val'
      end
    end

    context "intern option specified" do
      context "constraint is an array" do
        it "converts array entries to symbols" do
          Omega::Constraints.should_receive(:get).and_return(['a', 'b'])
          ConstrainedAttributeTest.get_constraint('constraint', :intern => true).
                                   should == [:a, :b]
        end
      end

      context "constraint is a hash" do
        it "converts hash keys to symbols" do
          Omega::Constraints.should_receive(:get).and_return({'a' => 'b'})
          ConstrainedAttributeTest.get_constraint('constraint', :intern => true).
                                   should == {:a => 'b'}
        end
      end

      it "converts constraint value to symbol" do
        Omega::Constraints.should_receive(:get).and_return('val')
        ConstrainedAttributeTest.get_constraint('constraint', :intern => true).
                                 should == :val
      end
    end
  end

  describe "::constraint_satisfied?" do
    context "constraint is an array" do
      context "value in array" do
        it "returns true" do
          ConstrainedAttributeTest.should_receive(:get_constraint).
                                   and_return([1, 2, 3])
          ConstrainedAttributeTest.constraint_satisfied?('constraint', 1).
                                   should be_true
        end
      end

      context "value not in array" do
        it "returns false" do
          ConstrainedAttributeTest.should_receive(:get_constraint).
                                   and_return([1, 2, 3])
          ConstrainedAttributeTest.constraint_satisfied?('constraint', 4).
                                   should be_false
        end
      end
    end

    context "<= qualifier specified" do
      context "new value is <= constraint" do
        it "returns true" do
          ConstrainedAttributeTest.should_receive(:get_constraint).and_return(3)
          ConstrainedAttributeTest.constraint_satisfied?('constraint', 2,
                                                         :qualifier => '<=').
                                   should be_true
        end
      end

      context "new value is not <= constraint" do
        it "returns false" do
          ConstrainedAttributeTest.should_receive(:get_constraint).and_return(3)
          ConstrainedAttributeTest.constraint_satisfied?('constraint', 4,
                                                         :qualifier => '<=').
                                   should be_false
        end
      end
    end

    context ">= qualifier specified" do
      context "new value is >= constraint" do
        it "returns true" do
          ConstrainedAttributeTest.should_receive(:get_constraint).and_return(3)
          ConstrainedAttributeTest.constraint_satisfied?('constraint', 4,
                                                         :qualifier => '>=').
                                   should be_true
        end
      end

      context "new value is not >= constraint" do
        it "returns false" do
          ConstrainedAttributeTest.should_receive(:get_constraint).and_return(3)
          ConstrainedAttributeTest.constraint_satisfied?('constraint', 2,
                                                         :qualifier => '>=').
                                   should be_false
        end
      end
    end

    context "value == constraint" do
      it "returns true" do
          ConstrainedAttributeTest.should_receive(:get_constraint).and_return(42)
          ConstrainedAttributeTest.constraint_satisfied?('constraint', 42).
                                   should be_true
      end
    end

    context "value != constraint" do
      it "returns false" do
        ConstrainedAttributeTest.should_receive(:get_constraint).and_return(42)
        ConstrainedAttributeTest.constraint_satisfied?('constraint', 43).
                                 should be_false
      end
    end
  end

  describe "::constraint_reader" do
    it "returns reader proc" do
      ConstrainedAttributeTest.constraint_reader('attr', 'constraint').
                                should be_an_instance_of(Proc)
    end

    describe "reader proc" do
      context "constraint explicity set" do
        it "returns explicit attribute value" do
          reader = ConstrainedAttributeTest.constraint_reader('attr', 'constraint')
          ConstrainedAttributeTest.should_receive(:explicitly_set?).
                                   with('attr').and_return(true)
          ConstrainedAttributeTest.should_receive(:explicit_value).
                                   with('attr').and_return('val')
          reader.call.should == 'val'
        end
      end

      context "nullable attribute" do
        it "returns nil" do
          reader = ConstrainedAttributeTest.constraint_reader('attr', 'constraint',
                                                              :nullable => true)
          ConstrainedAttributeTest.should_receive(:explicitly_set?).
                                   with('attr').and_return(false)
          reader.call.should be_nil
        end
      end

      it "returns constraint value" do
        reader = ConstrainedAttributeTest.constraint_reader('attr', 'constraint')
        ConstrainedAttributeTest.should_receive(:get_constraint).
                                 with('constraint', {}).and_return('val')
        ConstrainedAttributeTest.should_receive(:explicitly_set?).
                                 with('attr').and_return(false)
          reader.call.should == 'val'
      end
    end
  end

  describe "::constraint_wrapper" do
    it "returns wrapper proc" do
      bl = proc {}
      ConstrainedAttributeTest.constraint_wrapper('attr', 'constraint', &bl).
                                should be_an_instance_of(Proc)
    end

    describe "wrapper proc" do
      it "invokes block w/ constraint value" do
        called = false
        bl = proc { called = true }
        wrapper = ConstrainedAttributeTest.constraint_wrapper('attr', 'constraint', &bl)
        wrapper.call
        called.should be_true
      end

      it "returns block return value" do
        bl = proc { 42 }
        wrapper = ConstrainedAttributeTest.constraint_wrapper('attr', 'constraint', &bl)
        wrapper.call.should == 42
      end
    end
  end

  describe "::constraint_writer" do
    it "returns writer proc" do
      ConstrainedAttributeTest.constraint_writer('attr', 'constraint').
                                should be_an_instance_of(Proc)
    end

    describe "writer proc" do
      context "new value does not satisfy contraint" do
        it "raises an ArgumentError" do
          opts = {:op => :ts}
          writer = ConstrainedAttributeTest.constraint_writer('attr', 'constraint', opts)
          ConstrainedAttributeTest.should_receive(:constraint_satisfied?).
                                    with('constraint', 42, opts).
                                    and_return(false)
          lambda {
            writer.call 42
          }.should raise_error(ArgumentError)
        end
      end

      context "constraint is nullable and new value is nil" do
        it "sets value" do
          writer = ConstrainedAttributeTest.constraint_writer('attr', 'constraint', :nullable => true)
          ConstrainedAttributeTest.should_receive(:constraint_satisfied?).
                                    and_return(true)
          ConstrainedAttributeTest.should_receive(:explicitly_set!).
                                   with('attr', nil)
          writer.call nil
        end
      end

      context "contraint :intern options is true" do
        it "converts value to symbol" do
          writer = ConstrainedAttributeTest.constraint_writer('attr', 'constraint', :intern => true)
          ConstrainedAttributeTest.should_receive(:constraint_satisfied?).
                                    with('constraint', :foobar, {:intern => true}).
                                    and_return(true)
          ConstrainedAttributeTest.should_receive(:explicitly_set!).
                                   with('attr', :foobar)
          writer.call 'foobar'
        end
      end

      it "sets value" do
        writer = ConstrainedAttributeTest.constraint_writer('attr', 'constraint')
        ConstrainedAttributeTest.should_receive(:constraint_satisfied?).
                                  and_return(true)
        ConstrainedAttributeTest.should_receive(:explicitly_set!).
                                 with('attr', 'foobar')
        writer.call 'foobar'
      end
    end
  end

  describe "::constrained_attr" do
    before(:each) do
    end

    after(:each) do
      if(ConstrainedAttributeTest.method_defined?(:attr))
        ConstrainedAttributeTest.send :undef_method, :attr
      end
      if(ConstrainedAttributeTest.method_defined?(:attr=))
        ConstrainedAttributeTest.send :undef_method, :attr=
      end
    end

    it "stores constraint opts" do
      ConstrainedAttributeTest.should_receive(:constraint_opts).
                               with('attr', {:op => :ts})
      ConstrainedAttributeTest.constrained_attr('attr', :op => :ts)
    end

    it "defaults constraint to attribute" do
      ConstrainedAttributeTest.should_receive(:constraint_reader).
                               with('attr', 'attr', {}).
                               and_call_original
      ConstrainedAttributeTest.constrained_attr('attr')
    end

    context "block specified" do
      it "defines constraint wrapper" do
        called = false
        bl   = proc {}
        wrapper = proc { called = true}
        opts = {:constraint => 'constraint'}
        ConstrainedAttributeTest.should_receive(:constraint_wrapper).
                                 with('attr', 'constraint', opts, &bl).
                                 and_return(wrapper)
        ConstrainedAttributeTest.constrained_attr('attr', opts, &bl)
        ConstrainedAttributeTest.new.send :attr
        called.should be_true
      end
    end

    context "no block specified" do
      it "defines constraint reader" do
        called = false
        opts = {:constraint => 'constraint'}
        reader = proc { called = true}
        ConstrainedAttributeTest.should_receive(:constraint_reader).
                                 with('attr', 'constraint', opts).
                                 and_return(reader)
        ConstrainedAttributeTest.constrained_attr('attr', opts)
        ConstrainedAttributeTest.new.send :attr
        called.should be_true
      end
    end

    context "writable option is true" do
      it "defines constraint writer" do
        called = false
        opts = {:constraint => 'constraint', :writable => true}
        writer = proc { called = true}
        ConstrainedAttributeTest.should_receive(:constraint_writer).
                                 with('attr', 'constraint', opts).
                                 and_return(writer)
        ConstrainedAttributeTest.constrained_attr('attr', opts)
        ConstrainedAttributeTest.new.send :attr=
        called.should be_true
      end
    end

    it "returns nil" do
      ConstrainedAttributeTest.constrained_attr('attr').should be_nil
    end
  end

  describe "::constraint_opts" do
    before(:each) do
      @orig = ConstrainedAttributeTest.constraint_opts
    end

    after(:each) do
      ConstrainedAttributeTest.instance_variable_set(:@constrained_attrs, {})
      @orig.each_key { |k| ConstrainedAttributeTest.constraint_opts k, @orig[k]}
    end

    it "it sets/gets attribute options" do
      ConstrainedAttributeTest.constraint_opts 'attr', 'opts'
      ConstrainedAttributeTest.constraint_opts('attr').should == 'opts'
    end

    it "gets all attribute options" do
      ConstrainedAttributeTest.constraint_opts 'attr', 'opts'
      ConstrainedAttributeTest.constraint_opts.should == {'attr' => 'opts'}
    end
  end

  describe "#copy_constraints" do
    it "copies constraint options from specified class to local one"
  end
end # module ConstrainedAttributes
end # module Omega
