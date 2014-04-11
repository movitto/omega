# Manufactured Entity Validation
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/validate'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#dispatch_manufactured_rjr_validate" do
    after(:each) do
      # XXX need to remove validation callback added
      Manufactured::RJR.registry.validation_methods.delete \
        Manufactured::RJR::VALIDATE_METHODS[:validate_user_attributes]
    end

    it "adds validate user attributes to registry validation callbacks" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_validate(d)
      Manufactured::RJR.registry.validation_methods.size.should == 2
      Manufactured::RJR.registry.validation_methods.
        should include(Manufactured::RJR::VALIDATE_METHODS[:validate_user_attributes])

      dispatch_manufactured_rjr_validate(d)
      Manufactured::RJR.registry.validation_methods.size.should == 2
    end
  end
end #module Manufactured::RJR
