/* Omega Javascript Station
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega Station
 */
function Station(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  var station = this;
  this.json_class = 'Manufactured::Station';

  // convert location
  this.location = new Location(this.location);

  /// trigger a blank update to refresh components from current state
  this.refresh = function(){
    this.update(this);
  };

  // Return bool indicating if station belongs to the specified user
  this.belongs_to_user = function(user){
    return this.user_id == user;
  }

  // Return bool indicating if station belongs to current user
  this.belongs_to_current_user = function(){
    return Session.current_session != null &&
           this.belongs_to_user(Session.current_session.user_id);
  }

  /* override update
   */
  this.old_update = this.update;
  this.update = _station_update;

  // instantiate mesh to draw station on canvas
  this.create_mesh = _station_create_mesh;
  _station_load_mesh_resources(this);
  this.create_mesh();

  // effects to highlight ship
  this.highlight_pos = {x:0,y:200,z:0};
  this.highlight_effects = [];
  _station_create_highlight_effects(this);

  // some text to render in details box on click
  this.details = _station_render_details;

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = _station_clicked_in;

  /* unselected in scene callback
   */
  this.unselected_in = _station_unselected_in;

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;
  }
}

/* Return stations owned by the specified user
 */
Station.owned_by = function(user_id, cb){
  Entities().node().web_request('manufactured::get_entities',
                                'of_type', 'Manufactured::Station',
                                'owned_by', user_id, function(res){
    if(res.result){
      var stations = [];
      for(var e = 0; e < res.result.length; e++){
        stations.push(new Station(res.result[e]));
      }
      cb.apply(null, [stations])
    }
  });
}

///////////////////////// private helper / utility methods
/* Station::update method
 */
function _station_update(oargs){
  var args = $.extend({}, oargs); // copy args

  if(args.location && this.location){
    this.location.update(args.location);
    delete args.location;
  }

  if(this.selected){
    this.mesh.material.emissive.setHex(0xff0000);
  }else{
    this.mesh.material.emissive.setHex(0);
  }

  // do not update components from args
  if(args.components) delete args.components;

  this.old_update(args);
}

/* Station::create_mesh method
 */
function _station_create_mesh(){
  var station = this;
  if(this.mesh_geometry == null) return;

  this.mesh =
    UIResources().cached("station_" + this.id + "_mesh",
      function(i) {
        var mesh = new THREE.Mesh(station.mesh_geometry, station.mesh_material);
        mesh.position.x = station.location.x;
        mesh.position.y = station.location.y;
        mesh.position.z = station.location.z;
        mesh.rotation.x = mesh.rotation.y = mesh.rotation.z = 0;

        var scale = $omega_config.resources[station.type].scale;
        mesh.scale.x = scale[0];
        mesh.scale.y = scale[1];
        mesh.scale.z = scale[2];
        return mesh;
      });

  this.clickable_obj = this.mesh;
  this.components.push(this.mesh);

  // reload station if already in scene
  if(this.current_scene) this.current_scene.reload_entity(this);
}

/* Helper to load station mesh resources
 */
function _station_load_mesh_resources(station){
  station.mesh_material =
    UIResources().cached("station_"+station.id +"_material",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[station.type]['material'];
        var t = UIResources().load_texture(path);
        return new THREE.MeshLambertMaterial({map: t, overdraw: true});
    });

  var mesh_geometry =
    UIResources().cached('station_'+station.type+'_mesh_geometry',
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[station.type]['geometry'];
        UIResources().load_geometry(path, function(geo){
          station.mesh_geometry = geo;
          UIResources().set('station_'+station.type+'_mesh_geometry', station.mesh_geometry);
          station.create_mesh();
        });
        return null;
    });

}

/* Helper to create station highlight effects
 */
function _station_create_highlight_effects(station){
  var highlight_mesh =
    UIResources().cached('station_' + station.id + '_highlight_mesh',
      function(i){
        var geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
				var material =  new THREE.MeshBasicMaterial( { color:0x33ff33, shading: THREE.FlatShading } );
        var mesh = new THREE.Mesh(geometry, material);
        mesh.position.set(station.location.x + station.highlight_pos.x,
                          station.location.y + station.highlight_pos.y,
                          station.location.z + station.highlight_pos.z);
        mesh.rotation.set(3.14, 0, 0);
        return mesh;
      });

  station.highlight_effects.push(highlight_mesh)
  station.components.push(highlight_mesh);
}

/* Station::details method
 */
function _station_render_details(){
  var details = ['Station: ' + this.id + '<br/>',
                 '@ ' + this.location.to_s() + '<br/>',
                 "Resources: <br/>"];
  if(this.resources){
    for(var r = 0; r < this.resources.length; r++){
      var res = this.resources[r];
      details.push(res.quantity + " of " + res.material_id + "<br/>")
    }
  }

  if(this.belongs_to_current_user())
    details.push("<span id='cmd_construct' class='commands'>construct</span>");
  return details;
}

/* Station::clicked_in method
 */
function _station_clicked_in(scene){
  var station = this;
  $('#cmd_construct').die();
  $('#cmd_construct').live('click', function(e){
    Commands.construct_entity(station,
                              function(res){
                                if(res.error) ; // TODO
                                else
                                  station.raise_event('cmd_construct',
                                                      new Ship(res.result[1]));
                              });
  });

  this.selected = true;
  this.refresh();
  scene.reload_entity(this);
}

/* Station::unselected_in method
 */
function _station_unselected_in(scene){
  this.selected = false;
  this.refresh(); // refresh station components
  scene.reload_entity(this);
}
