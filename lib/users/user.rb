# Users module user definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users
class User
  attr_reader :id
  attr_reader :password
  attr_reader :alliances

  attr_reader :privileges

  def initialize(args = {})
    @id        = args['id']        || args[:id]
    @password  = args['password']  || args[:password]
    @alliances = args['alliances'] || args[:alliances] || []

    @privileges = []
    #Users::Registry.instance.create self
  end

  def add_alliance(alliance)
    @alliances << alliance unless @alliances.include?(alliance)
  end

  def add_privilege(privilege)
    @privileges << privilege unless @privileges.include?(privilege)
  end

  def valid_login?(user_id, password)
    self.id == user_id && self.password == password
  end

  def has_privilege_on?(privilege_id, entity_id)
    ! @privileges.find { |p| p.id == privilege_id && p.entity_id == entity_id }.nil?
  end

  def has_privilege?(privilege_id)
    has_privilege_on?(privilege_id, nil)
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
