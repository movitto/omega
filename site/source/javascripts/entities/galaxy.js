/* Omega Javascript Galaxy
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega Galaxy
 */
function Galaxy(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Cosmos::Entities::Galaxy';
  this.background = 'galaxy' + this.background;

  // override update
  this.old_update = this.update;
  this.update = _galaxy_update;

  // convert children
  this.location = new Location(this.location);
  this.solar_systems = [];
  if(this.children){
    for(var sys = 0; sys < this.children.length; sys++)
      this.solar_systems[sys] = new SolarSystem(this.children[sys]);
  }

  // return children
  this.children = function(){
    return this.solar_systems;
  }
}

/* Return galaxy with the specified id
 */
Galaxy.with_id = function(id, cb){
  Entities().node().web_request('cosmos::get_entity', 'with_id', id, function(res){
    if(res.result){
      var gal = new Galaxy(res.result);
      cb.apply(null, [gal]);
    }
  });
}

/* Galaxy::update method
 */
function _galaxy_update(oargs){
  var args = $.extend({}, oargs); // copy args

  if(args.location && this.location){
    this.location.update(args.location);
    delete args.location;
  }
  // assuming that system list is not variable
  if(args.solar_systems && this.solar_systems){
    for(var s = 0; s < args.solar_systems.length; s++)
      this.solar_systems[s].update(args.solar_systems[s]);
    delete args.solar_systems
  }
  this.old_update(args);
}
