# Omega Server Registry HasEntities Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'ostruct'
require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

module Omega
module Server
module Registry
  describe HasEntities do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)
    end

    describe "#entities" do
      it "returns all entities" do
        @registry << 1
        @registry << 2
        @registry.entities.should == [1, 2]
      end

      it "returns entities matching criteria" do
        @registry << 5
        @registry << 10
        @registry.entities { |e| e > 6 }.should == [10]
      end

      it "returns the copies of entities" do
        obj = { 'foo' => 'bar' }
        @registry << obj
        e = @registry.entities

        # test values are same but objects are not
        e.first.should == obj
        e.first.should_not equal(obj)
      end

      it "invokes retrieval on each entity" do
        @registry << OpenStruct.new(:id => 21)
        @registry << OpenStruct.new(:id => 42)
        e1 = @registry.safe_exec { |es| es.find { |i| i.id == 21 }}
        e2 = @registry.safe_exec { |es| es.find { |i| i.id == 42 }}

        @registry.retrieval.should_receive(:call).with(e1)
        @registry.retrieval.should_receive(:call).with(e2)
        e = @registry.entities
      end
    end

    describe "#entity" do
      it "returns first matching result" do
        @registry << 1
        @registry << 2
        @registry << 3
        selector = proc { |e| e % 2 != 0 }
        v = @registry.entity &selector
        v.should == 1
      end
    end

    describe "#clear!" do
      it "empties entities list" do
        @registry << 1
        @registry << 2
        @registry.clear!
        @registry.entities.should be_empty
      end
    end

    describe "#<<" do
      before(:each) do
        @added = nil
        @registry.on(:added) { |e| @added = e }
      end

      context "validation not set" do
        it "adds entity" do
          @registry << 1
          @registry << 1
          @registry.entities.should == [1, 1]
        end

        it "returns true" do
          @registry.<<(1).should be_true
          @registry.<<(1).should be_true
        end

        it "raises added event" do
          @registry << 1
          @added.should == 1

          @registry << 2
          @added.should == 2

          @registry << 1
          @added.should == 1
        end
      end

      context "validation is set" do
        before(:each) do
          @registry.validation_callback { |entities, e|
            !entities.include?(e)
          }
        end

        context "validation passes" do
          it "adds entity" do
            @registry << 1
            @registry << 2
            @registry.entities.should == [1,2]
          end

          it "returns true" do
            @registry.<<(1).should be_true
            @registry.<<(2).should be_true
          end

          it "raises added event" do
            @registry << 1
            @added.should == 1

            @registry << 2
            @added.should == 2
          end
        end

        context "validation fails" do
          it "doesn't add the entity" do
            @registry << 1
            @registry << 1
            @registry.entities.should == [1]
          end

          it "returns false" do
            @registry.<<(1).should be_true
            @registry.<<(1).should be_false
          end

          it "doesn't raise added event" do
            @registry << 1
            @added.should == 1

            @registry << 2
            @added.should == 2

            @registry << 1
            @added.should == 2
          end
        end
      end

      context "multiple validations are set" do
        before(:each) do
          @first = true
          @second = true
          @registry.validation_callback { |entities, e|
            @first
          }
          @registry.validation_callback { |entities, e|
            @second
          }
        end

        context "all validations passes" do
          it "adds entity" do
            @registry << 1
            @registry.entities.should == [1]
          end

          it "returns true" do
            @registry.<<(1).should be_true
          end

          it "raises added event" do
            @registry << 1
            @added.should == 1
          end
        end

        context "one or more validations fail" do
          before(:each) do
            @second = false
          end

          it "doesn't add the entity" do
            @registry << 1
            @registry.entities.should == []
          end

          it "returns false" do
            @registry.<<(1).should be_false
          end

          it "doesn't raise added event" do
            @registry << 1
            @added.should be_nil
          end
        end
      end
    end

    describe "#delete" do
      it "deletes first entity matching selector" do
        @registry << 1
        @registry << 2
        @registry << 3
        @registry.delete { |e| e % 2 != 0 }
        @registry.entities.should_not include(1)
        @registry.entities.should include(2)
        @registry.entities.should include(3)
      end

      context "entity deleted" do
        it "raises :deleted event" do
          @registry << 1
          @registry.should_receive(:raise_event).with(:deleted, 1)
          @registry.delete
        end

        it "returns true" do
          @registry << 1
          @registry.delete.should be_true
        end
      end

      context "entity not deleted" do
        it "does not raise :deleted event" do
          @registry.should_not_receive(:raise_event)
          @registry.delete { |e| false }
        end

        it "returns false" do
          @registry.delete { |e| false }.should be_false
        end
      end
    end

    describe "#update" do
      before(:each) do
        # primary entities (first two will be stored)
        @e1  = OmegaTest::ServerEntity.new(:id => 1, :val => 'a')
        @e2  = OmegaTest::ServerEntity.new(:id => 2, :val => 'b')
        @e3  = OmegaTest::ServerEntity.new(:id => 3, :val => 'c')

        # create an copy of e2/e3 which we will not modify (for validation)
        @orig_e2  = OmegaTest::ServerEntity.new(:id => 2, :val => 'b')
        @orig_e3  = OmegaTest::ServerEntity.new(:id => 3, :val => 'c')

        # create entities to use to update
        @e2a = OmegaTest::ServerEntity.new(:id => 2, :val => 'd')
        @e3a = OmegaTest::ServerEntity.new(:id => 3, :val => 'e')

        # define a selector which to use to select entities
        @select_e2 = proc { |e| e.id == @e2.id }
        @select_e3 = proc { |e| e.id == @e3.id }

        # update requires 'update' method on entities
        [@e1, @e2, @e3].each { |e|
          e.eigenclass.send(:define_method, :update,
                      proc { |v| self.val = v.val })
        }

        # add entities to registry
        @registry << @e1
        @registry << @e2

        # handle updated event
        @updated_n = @updated_o = nil
        @registry.on(:updated) { |n,o| @updated_n = n ; @updated_o = o }
      end

      context "selected entity found" do
        it "updates entity" do
          @registry.update(@e2a, &@select_e2)
          @e2.should == @e2a
        end

        it "raises updated event" do
          @registry.update(@e2a, &@select_e2)
          @updated_n.should == @e2a
          @updated_o.should == @orig_e2
        end

        it "returns true" do
          @registry.update(@e2a, &@select_e2).should == true
        end
      end

      context "selected entity not found" do
        it "does not update entity" do
          @registry.update(@e3a, &@select_e3)
          @e3.should == @orig_e3
        end

        it "does not raise updated event" do
          @registry.update(@e3a, &@select_e3)
          @updated_n.should be_nil
          @updated_o.should be_nil
        end

        it "returns false" do
          @registry.update(@e3a, &@select_e3).should be_false
        end
      end
    end
  end # describe HasEntities
end # module Registry
end # module Server
end # module Omega
