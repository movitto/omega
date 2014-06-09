# Missions DSL Helpers
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Missions
module DSL
module Helpers
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    # Update registry mission
    def update_mission(mission)
      Missions::RJR.registry.update(mission) { |m| m.id == mission.id }
    end
  
    # Provide access to centralized registry
    def registry
      Missions::RJR.registry
    end
  
    # Provide access to centralized node
    def node
      Missions::RJR.node
    end
  
    # Return bool if dsl module has specified method
    def has_dsl_method?(dsl_method)
      self.methods.collect { |m| m.to_s }.include?(dsl_method.to_s)
    end

    # List of mission callbacks mapped to default DSL categories
    def dsl_categories
      @dsl_categories ||= {:requirements         => Missions::DSL::Requirements,
                           :assignment_callbacks => Missions::DSL::Assignment,
                           :victory_conditions   => Missions::DSL::Query,
                           :victory_callbacks    => Missions::DSL::Resolution,
                           :failure_callbacks    => Missions::DSL::Resolution}
    end
  
    # Return DSL category from name or configured for mission callback
    def dsl_category_for(cb_type)
      dsl_categories[cb_type]
    end
  end # module ClassMethods

  # Return DSL module w/ specified name
  def dsl_module_for(name)
    Missions::DSL.const_get(name.intern)
  end

  # Return bool indicating if category is a DSL category
  def is_dsl_category?(category)
    Missions::DSL.constants.collect { |c| c.to_s }.include?(category.to_s)
  end
end # end Helpers
end # end DSL
end # end Missions
