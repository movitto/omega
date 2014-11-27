# Omega Spec Attributes Helpers
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# Helper to enable server-side attribute system
def enable_attributes
  o = Users::RJR.user_attrs_enabled
  Users::RJR.user_attrs_enabled = true
  r = yield
  Users::RJR.user_attrs_enabled = o
  r
end

module OmegaTest
  class Attribute < Users::AttributeClass
    id :test_attribute
    description 'test attribute description'
    multiplier 5
    callbacks :level_up    => lambda { |attr| @level_up_invoked    = true },
              :level_down  => lambda { |attr| @level_down_invoked  = true },
              :progression => lambda { |attr| @progression_invoked = true },
              :regression  => lambda { |attr| @regression_invoked  = true }

    def self.reset_callbacks
      @level_up_invoked    = false
      @level_down_invoked  = false
      @progression_invoked = false
      @regression_invoked  = false
    end

    def self.level_up ; @level_up_invoked ; end
    def self.level_down ; @level_down_invoked ; end
    def self.progression ; @progression_invoked ; end
    def self.regression ; @regression_invoked ; end
  end
end
