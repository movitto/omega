# Users module user definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users
class User
  attr_reader :id
  attr_reader :password
  attr_reader :alliances

  def initialize(args = {})
    @id        = args['id']        || args[:id]
    @password  = args['password']  || args[:password]
    @alliances = args['alliances'] || args[:alliances] || []

    #Users::Registry.instance.create self
  end

  def add_alliance(alliance)
    @alliances << alliance unless @alliances.include?(alliance)
  end

  def valid_login?(user_id, password)
    self.id == user_id && self.password == password
  end

  # TODO at some point implement a full RBAC solution
  def is_authorized?(privilege, entity = nil)
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :password => password, :alliances => alliances}
    }.to_json(*a)
  end

  def self.json_create(o)
    user = new(o['data'])
    return user
  end

end
end
