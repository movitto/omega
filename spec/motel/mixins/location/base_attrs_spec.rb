# Location BaseAttrs Mixin Specs
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'

module Motel
describe Location do
  let(:loc)   { build(:location) }
  let(:other) { build(:location) }

  describe "#base_attrs_from_args" do
    it "initializes id" do
      loc.base_attrs_from_args :id => 'loc1'
      loc.id.should == 'loc1'
    end

    it "initializes restrict_view" do
      loc.base_attrs_from_args :restrict_view => false
      loc.restrict_view.should be_false
    end

    it "initializes restrict_modify" do
      loc.base_attrs_from_args :restrict_modify => false
      loc.restrict_modify.should be_false
    end

    it "should default to restricting view and modify" do
      loc.base_attrs_from_args({})
      loc.restrict_view.should be_true
      loc.restrict_modify.should be_true
    end
  end

  describe "#id_valid" do
    context "id is nil" do
      it "returns false" do
        loc.id = nil
        loc.id_valid?.should be_false
      end
    end

    context "id is not nil" do
      it "returns true" do
        loc.id = 'loc1'
        loc.id_valid?.should be_true
      end
    end
  end

  describe "#base_json" do
    it "returns base attributes json data hash" do
      loc.base_json.should be_an_instance_of(Hash)
    end

    it "returns id in json data hash" do
      loc.id = 'loc1'
      loc.base_json[:id].should == 'loc1'
    end

    it "returns restrict view in json data hash" do
      loc.restrict_view = false
      loc.base_json[:restrict_view].should be_false
    end

    it "returns restrict modify in json data hash" do
      loc.restrict_modify = false
      loc.base_json[:restrict_modify].should be_false
    end
  end

  describe "#base_attrs_eql?" do
    before(:each) do
      loc.id = other.id = 'loc1'
      loc.restrict_view = other.restrict_view = true
      loc.restrict_modify = other.restrict_modify = true
    end

    context "id != other.id" do
      it "returns false" do
        loc.id = 'foo'
        other.id = 'bar'
        loc.base_attrs_eql?(other).should be_false
      end
    end

    context "restrict_view != other.restrict_view" do
      it "returns false" do
        loc.restrict_view = true
        other.restrict_view = false
        loc.base_attrs_eql?(other).should be_false
      end
    end

    context "restrict_modify != other.restrict_modify" do
      it "returns false" do
        loc.restrict_modify = true
        other.restrict_modify = false
        loc.base_attrs_eql?(other).should be_false
      end
    end

    it "returns true" do
      loc.base_attrs_eql?(other).should be_true
    end
  end
end # describe Location
end # module Motel
