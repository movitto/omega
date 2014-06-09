# manufactured::subscribe_to helpers specs
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/subscribe_to/helpers'

module Manufactured::RJR
  describe "subscribable_entity?" do
    include Manufactured::RJR

    before(:each) do
      should_receive(:rjr_env).and_return(Manufactured::RJR)
    end

    context "ship or station" do
      it "returns true" do
        subscribable_entity?(Manufactured::Ship.new).should be_true
      end
    end

    context "anything else" do
      it "returns false" do
        subscribable_entity?(42).should be_false
      end
    end
  end
end # module Manufactured::RJR
