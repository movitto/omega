# Manufactured Entity Validation
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/validate'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#validate_user_attributes", :rjr => true do
    include Omega::Server::DSL # for with_id below
    include Manufactured::RJR

    before(:each) do
      setup_manufactured
    end

    context "user has maximum number of entities" do
      it "returns false" do
        enable_attributes {
          attr = Users::Attributes::EntityManagementLevel
          sh = create(:valid_ship)
          Users::RJR.registry.safe_exec { |entities|
            entities.find(&with_id(sh.user_id)).attribute(attr.id).level = 1
          }

          lambda{
            validate_user_attributes(Manufactured::RJR.registry.entities, sh)
          }.should raise_error(Omega::PermissionError)
        }
      end
    end

    it "returns true" do
      enable_attributes {
        attr = Users::Attributes::EntityManagementLevel
        sh = create(:valid_ship)
        Users::RJR.registry.safe_exec { |entities|
          entities.find(&with_id(sh.user_id)).attribute(attr.id).level = 2
        }

        lambda{
          validate_user_attributes(Manufactured::RJR.registry.entities, sh)
        }.should_not raise_error
      }
    end
  end

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
