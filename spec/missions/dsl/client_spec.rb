# Missions DSL Client Module tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl/client'

module Missions
module DSL
module Client
  describe Proxy do
    describe "::method_missing" do
      context "dsl method invoked on Proxy" do
        it "returns new Proxy encapsulating method" do
          st = build(:station)
          p = Proxy.docked_at st
          p.should be_an_instance_of(Proxy)
          p.dsl_category.should == "Requirements"
          p.dsl_method.should   == "docked_at"
          p.params.should == [st]
        end
      end

      context "non-dsl method invoked on Proxy" do
        it "returns nil" do
          n = Proxy.foobar
          n.should be_nil
        end
      end
    end

    describe "::resolve" do
      it "resolves all proxy references in all mission callbacks" do
        m = build(:mission)
        pr1 = proc {}
        proxy1 = Proxy.new

        m.requirements << pr1
        m.requirements << proxy1

        proxy1.should_receive(:resolve)
        Proxy.resolve(:mission => m)
      end
    end

    describe "#resolve" do
      before(:each) do
        @p = Proxy.new :dsl_category => Missions::DSL::Requirements,
                       :dsl_method   => :docked_at
      end

      context "invalid dsl category" do
        it "returns nil" do
          p = Proxy.new :dsl_category => 'Foobar'
          p.resolve.should be_nil
        end
      end

      context "invalid dsl method" do
        it "returns nil" do
          p = Proxy.new :dsl_category => 'Requirements',
                        :dsl_method   => 'create_entity'
          p.resolve.should be_nil
        end
      end

      it "resolves all proxy params" do
        p = Proxy.new
        @p.params << p
        p.should_receive(:resolve)
        @p.resolve
      end

      it "invokes dsl category method with params and return result" do
        @p.params << 42
        DSL::Requirements.should_receive(:docked_at).with(42).and_return(24)
        @p.resolve.should == 24
      end
    end

    describe "#to_json" do
      it "returns proxy in json format" do
        p = Proxy.new :dsl_category => 'Query',
                      :dsl_method => 'check_mining_quantity',
                      :params => [42]
        j = p.to_json
        j.should include('"json_class":"Missions::DSL::Client::Proxy"')
        j.should include('"dsl_category":"Query"')
        j.should include('"dsl_method":"check_mining_quantity"')
        j.should include('"params":[42]')
      end
    end

    describe "#json_create" do
      it "returns proxy from json format" do
        j = '{"json_class":"Missions::DSL::Client::Proxy","data":{"dsl_category":"Query","dsl_method":"check_mining_quantity","params":[42]}}'
        p = ::RJR.parse_json(j)

        p.class.should == Missions::DSL::Client::Proxy
        p.dsl_category.should == 'Query'
        p.dsl_method.should == 'check_mining_quantity'
        p.params.should == [42]
      end
    end
  end
end # module Client
end # module DSL
end # module Missions
