# Users module user definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users
class User
  attr_reader :id
  attr_reader :alliances

  def initialize(args = {})
    @id        = args['id']        || args[:id]
    @alliances = args['alliances'] || args[:alliances] || []

    #Users::Registry.instance.create self
  end

  def add_alliance(alliance)
    @alliances << alliance unless @alliances.include?(alliance)
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :alliances => alliances}
    }.to_json(*a)
  end

  def self.json_create(o)
    user = new(o['data'])
    return user
  end

end
end
