/* Omega Javascript Ship
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega Ship
 */
function Ship(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  var ship = this;
  this.json_class = 'Manufactured::Ship';
  this.ignore_properties.push('highlight_effects');
  this.ignore_properties.push('lamps');
  this.ignore_properties.push('trails');

  // convert location
  this.location = new Location(this.location);

  // override update
  this.old_update = this.update;
  this.update     = _ship_update;

  // trigger a blank update to refresh components from current state
  this.refresh = function(){
    this.update(this);
  }

  // Return bool indicating if ship belongs to the specified user
  this.belongs_to_user = function(user){
    return this.user_id == user;
  }

  // Return bool indicating if ship belongs to current user
  this.belongs_to_current_user = function(){
    return Session.current_session != null &&
           this.belongs_to_user(Session.current_session.user_id);
  }

  // helper to set orientation
  this.set_orientation = _ship_set_orientation;

  // instantiate mesh to draw ship on canvas
  this.create_mesh = _ship_create_mesh; 
  _ship_load_mesh_resources(this);
  this.create_mesh();

  // effects to highlight ship
  this.highlight_pos = {x:0,y:200,z:0};
  this.highlight_effects = [];
  _ship_create_highlight_effects(this);

  // lamps to add to the ship
  _ship_create_lamps(this);

  // create trails at the specified coordinates relative to ship
  // in accordance to ship config options
  this.create_trail = _ship_create_trail;
  _ship_load_trails(this);

  // setup attack and mining vectors
  _ship_create_attack_vector(this);
  _ship_create_mining_vector(this);

  // some text to render in details box on click
  this.details = _ship_render_details; 

  // text to render in popup on selection command click
  this.selection = _ship_selection;

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = _ship_clicked_in;

  /* unselected in scene callback
   */
  this.unselected_in = function(scene){
    this.selected = false;
    this.refresh(); // refresh ship components
    scene.reload_entity(this);
  }

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;
  }

  // XXX run new update method
  // (a bit redunant w/ update invoked in Entity constructor)
  this.update(args);

  // run ship timer if not already running
  Ship.run_timer.play();
}

/* Return ship w/ the specified id
 */
Ship.with_id = function(id, cb){
  Entities().node().web_request('manufactured::get_entity', 'with_id', id, function(res){
    if(res.result){
      var ship = new Ship(res.result);
      cb.apply(null, [ship]);
    }
  });
};

/* Return ships owned by the specified user
 */
Ship.owned_by = function(user_id, cb){
  Entities().node().web_request('manufactured::get_entities',
                                'of_type', 'Manufactured::Ship',
                                'owned_by', user_id, function(res){
    if(res.result){
      var ships = [];
      for(var e = 0; e < res.result.length; e++){
        ships.push(new Ship(res.result[e]));
      }
      cb.apply(null, [ships])
    }
  });
}

///////////////////////// private helper / utility methods

/* helper to lookup mining target in local registry
 *
 * (needs to be defined before update is called)
 */
function _ship_resolve_mining_target(sys_id, mining_target){
  var sys  = Entities().get(sys_id);
  var asts = sys ? sys.asteroids : [];
  for(var a = 0; a < asts.length; a++)
    if(asts[a].id == mining_target.entity_id)
      return asts[a];
  return null;
}

/* Ship::update method
 */
function _ship_update(oargs){
  var args = $.extend({}, oargs); // copy args

  var to_remove = [];

  if(args.location && this.location){
    this.location.update(args.location);

    // XXX update necessary propetries update method ignores
    this.location.json_class = args.location.json_class;
    if(args.location.movement_strategy)
      this.location.movement_strategy = args.location.movement_strategy;

    delete args.location;
  }

  // always update mesh to reflect current position / orientation...
  if(this.mesh){
    this.mesh.position.x = this.location.x;
    this.mesh.position.y = this.location.y;
    this.mesh.position.z = this.location.z;
    this.set_orientation(this.mesh, true)

    // also update visual attributes depending on if ship is selected
    if(this.selected){
      this.mesh.material.emissive.setHex(0xff0000);
    }else{
      this.mesh.material.emissive.setHex(0);
    }
  }

  // same w/ shader mesh
  if(this.shader_mesh){
    this.shader_mesh.position.x = this.location.x;
    this.shader_mesh.position.y = this.location.y;
    this.shader_mesh.position.z = this.location.z;
    this.set_orientation(this.shader_mesh, true)
  }

  // ...same w/ highlight effects...
  if(this.highlight_effects){
    for(var e = 0; e < this.highlight_effects.length; e++){
      this.highlight_effects[e].position.set(this.location.x + this.highlight_pos.x,
                                             this.location.y + this.highlight_pos.y,
                                             this.location.z + this.highlight_pos.z);
    }
  }

  // ...same with lamps...
  if(this.lamps){
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      var conf_lamp = $omega_config.resources[this.type].lamps[l];
      lamp.position.set(this.location.x + conf_lamp[2][0],
                        this.location.y + conf_lamp[2][1],
                        this.location.z + conf_lamp[2][2])
      this.set_orientation(lamp, false);
    }
  }

  // ...same w/ trails...
  if(this.trails){
    for(var t = 0; t < this.trails.length; t++){
      var trail = this.trails[t];
      var conf_trail = $omega_config.resources[this.type].trails[t];
      trail.position.x = this.location.x + conf_trail[0];
      trail.position.y = this.location.y + conf_trail[1];
      trail.position.z = this.location.z + conf_trail[2];
      this.set_orientation(trail, false);

      // do not display trail if stopped
      if(!this.location.movement_strategy ||
         this.location.movement_strategy.json_class ==
         'Motel::MovementStrategies::Stopped'){
         if(this.components.indexOf(trail) != -1)
           to_remove.push(trail);

      // otherwise dispay trail
      }else if(this.components.indexOf(trail) == -1){
        this.components.push(trail);

      //TODO different types of trails for rotation/linear movement
      }
    }
  }

  // ...same w/ attack line...
  if(this.attack_particles){
    this.attack_particles.position.x = this.location.x;
    this.attack_particles.position.y = this.location.y;
    this.attack_particles.position.z = this.location.z;
  }

  // ...same w/ mining line...
  if(this.mining_line){
    this.mining_line_geo.vertices[0].x = this.location.x;
    this.mining_line_geo.vertices[0].y = this.location.y;
    this.mining_line_geo.vertices[0].z = this.location.z;
  }

  // handle attack state changes
  if(args.attacking){
    // TODO _ship_resolve_attack_target (also for defense target?)
    if(this.attack_particles){
      if(this.components.indexOf(this.attack_particles) == -1)
        this.components.push(this.attack_particles);

      this.refresh_attack_particles(this.attack_particles.geometry,
                                    args.attacking.location)
    }

  }else if(this.attacking){
    if(this.attack_particles)
      to_remove.push(this.attack_particles)
  }

  // handle mining state changes
  if(args.mining){
    this.mining = args.mining;
    this.mining.entity = _ship_resolve_mining_target(this.system_id, this.mining);

    if(this.mining_line){
      if(this.components.indexOf(this.mining_line) == -1)
        this.components.push(this.mining_line);

      this.mining_line_geo.vertices[1].x = this.mining.entity.location.x;
      this.mining_line_geo.vertices[1].y = this.mining.entity.location.y;
      this.mining_line_geo.vertices[1].z = this.mining.entity.location.z;
    }

  }else if(this.mining && this.mining_line){
    to_remove.push(this.mining_line);
  }

  // remove any components during reload scene callback
  if(this.current_scene) this.current_scene.reload_entity(this, function(s, e){
    for(var r = 0; r < to_remove.length; r++)
      e.components.splice(e.components.indexOf(to_remove[r]), 1);
  });

  // do not update components from args
  if(args.components) delete args.components;

  this.old_update(args);
}

/* Ship::set_orientation method
 */
function _ship_set_orientation(component, is_mesh){
  // apply base mesh rotation
  var rotation = $omega_config.resources[this.type].rotation
  component.rotation.x = component.rotation.y = component.rotation.z = 0;
  if(rotation){
    component.rotation.x = rotation[0];
    component.rotation.y = rotation[1];
    component.rotation.z = rotation[2];
  }
  component.matrix.makeRotationFromEuler(component.rotation);

  // set location orientation
  var oax = cp(0, 0, 1, this.location.orientation_x,
                        this.location.orientation_y,
                        this.location.orientation_z);
  var oab = abwn(0, 0, 1, this.location.orientation_x,
                          this.location.orientation_y,
                          this.location.orientation_z);

  if(Math.abs(oab) > 0.0001){
    oax = nrml(oax[0], oax[1], oax[2]);

    // XXX edge case if facing straight back to preserve 'top'
    // TODO expand this to cover all cases where oab > 1.57 or < -1.57
    if(Math.abs(oab - Math.PI) < 0.0001) oax = [0,1,0];
    var orm = new THREE.Matrix4().makeRotationAxis({x:oax[0], y:oax[1], z:oax[2]}, oab);
    orm.multiply(component.matrix);
    component.rotation.setEulerFromRotationMatrix(orm);

    // rotate everything other than mesh around mesh itself
    if(!is_mesh){
      var aa = new THREE.Vector3();
      aa.set(component.position.x - this.location.x,
             component.position.y - this.location.y,
             component.position.z - this.location.z)
      var d = aa.length();
      aa.transformDirection(orm);

      component.position.x = aa.x * d + this.location.x;
      component.position.y = aa.y * d + this.location.y;
      component.position.z = aa.z * d + this.location.z;
    }
  }
}

/* Ship::create_mesh method
 */
function _ship_create_mesh(){
  var ship = this;
  if(this.mesh_geometry == null) return;
  this.mesh =
    UIResources().cached("ship_" + this.id + "_mesh",
      function(i) {
        var mesh = new THREE.Mesh(ship.mesh_geometry, ship.mesh_material);
        mesh.position.x = ship.location.x;
        mesh.position.y = ship.location.y;
        mesh.position.z = ship.location.z;

        var scale = $omega_config.resources[ship.type].scale;
        if(scale){
          mesh.scale.x = scale[0];
          mesh.scale.y = scale[1];
          mesh.scale.z = scale[2];
        }

        ship.set_orientation(mesh, true);
        return mesh;
      });

  this.shader_mesh =
    UIResources().cached("ship_" + this.id + "_shader_mesh",
      function(i) {
        var mesh = new THREE.Mesh(ship.mesh_geometry.clone(),
                                  new THREE.MeshBasicMaterial({color: 0x000000}));
        mesh.position = ship.mesh.position;
        mesh.rotation = ship.mesh.rotation;
        mesh.scale    = ship.mesh.scale;
        return mesh;
      });

  if(this.hp > 0){
    this.clickable_obj = this.mesh;
    this.components.push(this.mesh);
    this.shader_components.push(this.shader_mesh);
  }

  // reload entity if already in scene
  if(this.current_scene) this.current_scene.reload_entity(this);
}

/* helper to load mesh resources for a ship
 */
function _ship_load_mesh_resources(ship){
  ship.mesh_material =
    UIResources().cached("ship_"+ship.id+"_mesh_material",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[ship.type]['material'];
        var t = UIResources().load_texture(path);
        // lambert material is more resource intensive than basic and
        // requires a light source but is needed to modify emissive
        // properties for selection indication in update above
        return new THREE.MeshLambertMaterial({map: t, overdraw: true});
      });

  ship.mesh_geometry =
    UIResources().cached('ship_'+ship.type+'_mesh_geometry',
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[ship.type]['geometry'];
        UIResources().load_geometry(path, function(geo){
          ship.mesh_geometry = geo;
          UIResources().set('ship_'+ship.type+'_mesh_geometry', ship.mesh_geometry)
          ship.create_mesh();
        })
        return null;
      });
}

/* Ship::create_trail method
 */
function _ship_create_trail(x,y,z){
  //// create a particle system for ship trail
  var plane = 3, lifespan = 20;
  var pMaterial =
    UIResources().cached('ship_tail_material',
      function(i) {
        return new THREE.ParticleBasicMaterial({
                     color: 0xFFFFFF, size: 20,
                     map: UIResources().load_texture(UIResources().images_path + "/particle.png"),
                     blending: THREE.AdditiveBlending, transparent: true });
      });

  // FIXME cache this & particle system (requires a cached instance
  // for each ship tail created)
  var particles = new THREE.Geometry();
  for(var i = 0; i < plane; ++i){
    for(var j = 0; j < plane; ++j){
      var pv = new THREE.Vector3(i, j, 0);
      pv.velocity = Math.random();
      pv.lifespan = Math.random() * lifespan;
      if(i >= plane / 4 && i <= 3 * plane / 4 &&
         j >= plane / 4 && j <= 3 * plane / 4 ){
           pv.lifespan *= 2;
           pv.velocity *= 2;
      }
      pv.olifespan = pv.lifespan;
      particles.vertices.push(pv)
    }
  }

  var particleSystem = new THREE.ParticleSystem(particles, pMaterial);
  particleSystem.position.x = x;
  particleSystem.position.y = y;
  particleSystem.position.z = z;
  particleSystem.sortParticles = true;

  particleSystem.update_particles = function(){
    var p = plane*plane;
    while(p--){
      var pv = this.geometry.vertices[p]
      pv.z -= pv.velocity;
      pv.lifespan -= 1;
      if(pv.lifespan < 0){
        pv.z = 0;
        pv.lifespan = pv.olifespan;
      }
    }
    this.geometry.__dirtyVertices = true;
  }

  return particleSystem;
}

/* Helper to create ship highlight effects
 */
function _ship_create_highlight_effects(ship){

  var highlight_light =
    UIResources().cached('ship_' + ship.id + '_highlight_light',
      function(i){
        var light = new THREE.DirectionalLight(0xFFFFFF, 1);
        light.position.set(ship.location.x + ship.highlight_pos.x,
                           ship.location.y + ship.highlight_pos.y,
                           ship.location.z + ship.highlight_pos.z);
        light.rotation.set(1.57, 0, 0);
        return light;
      });

  var highlight_mesh =
    UIResources().cached('ship_' + ship.id + '_highlight_mesh',
      function(i){
        var geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
				var material =  new THREE.MeshBasicMaterial( { color:0x33ff33, shading: THREE.FlatShading } );
        var mesh = new THREE.Mesh(geometry, material);
        mesh.position.set(ship.location.x + ship.highlight_pos.x,
                          ship.location.y + ship.highlight_pos.y,
                          ship.location.z + ship.highlight_pos.z);
        mesh.rotation.set(3.14, 0, 0);
        return mesh;
      });

  if(!highlight_mesh) return;

  //ship.highlight_effects.push(highlight_light)
  //ship.components.push(highlight_light);

  ship.highlight_effects.push(highlight_mesh)
  ship.components.push(highlight_mesh);
}

/* Helper to load/create lamps from config
 */
function _ship_create_lamps(ship){
  var lamps = ship.type ? $omega_config.resources[ship.type].lamps : null;
  if(lamps){
    ship.lamps = [];
    for(var t = 0; t < lamps.length; t++){
      var lamp  = lamps[t];
      var nlamp = create_lamp(lamp[0], lamp[1])
      nlamp.position.set(ship.location.x + lamp[2][0],
                         ship.location.y + lamp[2][1],
                         ship.location.z + lamp[2][2])
      ship.lamps.push(nlamp);
      ship.components.push(nlamp);
    }
  }
}

/* Helper to load ship trails from config
 */
function _ship_load_trails(ship){
  var trails = ship.type ? $omega_config.resources[ship.type].trails : null;
  if(trails){
    ship.trails = [];
    for(var t = 0; t < trails.length; t++){
      var trail  = trails[t];
      var ntrail = ship.create_trail(trail[0], trail[1], trail[2])
      ship.trails.push(ntrail);
    }
  }
}

/* Helper to create ship attack vector
 */
function _ship_create_attack_vector(ship){
  var particle_material =
    UIResources().cached('ship_attacking_particle_material',
      function(i) {
        return new THREE.ParticleBasicMaterial({
                     color: 0xFF0000, size: 20,
                     map: UIResources().load_texture(UIResources().images_path + "/particle.png"),
                     blending: THREE.AdditiveBlending, transparent: true });
      });

  ship.refresh_attack_particles = function(geo, target_loc){
    var dist = ship.location.distance_from(target_loc.x,
                                           target_loc.y,
                                           target_loc.z);
    // should be signed to preserve direction
    var dx = target_loc.x - ship.location.x;
    var dy = target_loc.y - ship.location.y;
    var dz = target_loc.z - ship.location.z;

    // 5 unit particle + 55 unit spacer
    var num = dist / 60;
    geo.scalex = 60 / dist * dx;
    geo.scaley = 60 / dist * dy;
    geo.scalez = 60 / dist * dz;

    for(var i = geo.vertices.length; i < num; ++i){
      geo.vertices.push(new THREE.Vector3(0,0,0));
    }
  }

  var particle_geo =
    UIResources().cached('ship_' + ship.id + '_attacking_particle_geometry',
      function(i) {
        var geo = new THREE.Geometry();
        if(ship.attacking){
          ship.refresh_attack_particles(geo, ship.attacking.location);
        }
        return geo;
      });

  ship.attack_particles =
    UIResources().cached('ship_' + ship.id + '_attacking_particle_system',
      function(i){
        var particleSystem =
          new THREE.ParticleSystem(particle_geo,
                                   particle_material);
        particleSystem.position.x = ship.location.x;
        particleSystem.position.y = ship.location.y;
        particleSystem.position.z = ship.location.z;
        particleSystem.sortParticles = true;

        particleSystem.update_particles = function(){
          for(var p = 0; p < this.geometry.vertices.length; p++){
            var v = this.geometry.vertices[p];
            if(Math.floor( Math.random() * 25 ) == 1)
              v.moving = true;
            if(v.moving){
              v.x += this.geometry.scalex;
              v.y += this.geometry.scaley;
              v.z += this.geometry.scalez;
            }

            // FIXME if attack distance is great each individual particle hop
            // may take it > 60 units away, skipping this entirely / moving the
            // particle off to infinity
            if(ship.attacking.location.distance_from(ship.location.x + v.x,
                                                     ship.location.y + v.y,
                                                     ship.location.z + v.z) < 60){
              v.x = v.y = v.z = 0;
              v.moving = false;
            }
          }
          this.geometry.__dirtyVertices = true;
        };

        return particleSystem;
      });
}

/* Helper to create ship mining vector
 */
function _ship_create_mining_vector(ship){
  var line_material =
    UIResources().cached('ship_mining_material',
      function(i) {
        return new THREE.LineBasicMaterial({color: 0x0000FF});
      });

  ship.mining_line_geo =
    UIResources().cached('ship_'+ship.id+'_mining_geometry',
                         function(i) {
                           var geometry = new THREE.Geometry();
                           var av = ship.mining && ship.mining.entity ?
                                    ship.mining.entity.location : {x:0, y:0, z:0};
                           geometry.vertices.push(new THREE.Vector3(ship.location.x,
                                                                    ship.location.y,
                                                                    ship.location.z));
                           geometry.vertices.push(new THREE.Vector3(av[0], av[1], av[2]));

                           return geometry;
                         });
  ship.mining_line =
    UIResources().cached('ship_'+ship.id+'_mining_line',
                         function(i) {
                           var line = new THREE.Line(ship.mining_line_geo, line_material);
                           return line;
                         });

}

/* Ship::details method
 */
function _ship_render_details(){
  var details = ['Ship: ' + this.id + '<br/>',
                 '@ ' + this.location.to_s() + '<br/>',
                 "Resources: <br/>"];
  if(this.resources){
    for(var r = 0; r < this.resources.length; r++){
      var res = this.resources[r];
      details.push(res.quantity + " of " + res.material_id + "<br/>")
    }
  }

  if(this.belongs_to_current_user()){
    details.push("<span id='cmd_move_select' class='commands'>move</span>");
    details.push("<span id='cmd_attack_select' class='commands'>attack</span>");
    var dcss = this.docked_at_id ? 'display: none' : '';
    var ucss = this.docked_at_id ? '' : 'display: none';
    details.push("<span id='cmd_dock_select' class='commands' style='" + dcss + "'>dock</span>");
    details.push("<span id='cmd_undock' class='commands' style='" + ucss + "'>undock</span>");
    details.push("<span id='cmd_transfer' class='commands' style='" + ucss + "'>transfer</span>");
    details.push("<span id='cmd_mine_select' class='commands'>mine</span>");
  }

  return details;
}

/* Ship selection
 */
var _ship_selection =
  { 'cmd_move_select' :
      ['Move Ship',
       function(){
        // coordinate specification
        // TODO also render a list of entities in selected system, populated this w/ an entity's location if clicked
        return "<div class='dialog_row'>" + this.id + "</div>" +
               "<div class='dialog_row'>X: <input id='dest_x' type='text' value='"+roundTo(this.location.x,2)+"'/></div>" +
               "<div class='dialog_row'>Y: <input id='dest_y' type='text' value='"+roundTo(this.location.y,2)+"'/></div>" +
               "<div class='dialog_row'>Z: <input id='dest_z' type='text' value='"+roundTo(this.location.z,2)+"'/></div>" +
               "<div class='dialog_row'><input type='button' value='move' id='cmd_move' /></div>";
       }] ,

    'cmd_attack_select' :
      ['Launch Attack',
       function(){
        // load attack target selection from ships in the vicinity
        var ship = this;
        var entities = Entities().select(function(e) {
          return e.json_class == 'Manufactured::Ship'            &&
                 e.user_id    != Session.current_session.user_id &&
                 e.hp > 0 &&
                 e.location.is_within(ship.attack_distance, ship.location);
        });

        var text = "Select " + this.id + " target<br/>";
        for(var e = 0; e < entities.length; e++){
          var entity = entities[e];
          text += '<span id="cmd_attack_'+entity.id+'" class="cmd_attack dialog_cmds">' + entity.id + '</span>';
        }
        return text;
      }],

    'cmd_dock_select' :
      ['Dock Ship',
       function(){
        // load dock target selection from stations in the vicinity
        var ship = this;
        var entities = Entities().select(function(e) {
          return e.json_class == 'Manufactured::Station' &&
                 e.belongs_to_current_user() &&
                 e.location.is_within(e.docking_distance, ship.location);
        });

        var text = 'Dock ' + this.id + ' at<br/>';
        for(var e = 0; e < entities.length; e++){
          var entity = entities[e];
          text += '<span id="cmd_dock_' + entity.id + '" class="cmd_dock dialog_cmds">' + entity.id + '</span>';
        }
        return text;
      }],

    'cmd_mine_select' :
      ['Start Mining',
       function(){
        return "Select resource to mine with "+ this.id +" <br/>";
      }]
  };

/* Ship::clicked_in method
 */
function _ship_clicked_in(scene){
  var ship = this;

  // remove existing command page element handlers
  // XXX should be exact same selectors as w/ live handlers below:
  $('#cmd_move_select,#cmd_attack_select,' +
    '#cmd_dock_select,#cmd_mine_select').die();
  $('#cmd_move').die()
  $('.cmd_attack').die()
  $('.cmd_dock').die();
  $('#cmd_undock').die();
  $('#cmd_transfer').die();
  $('.cmd_mine').die();

  // wire up selection command page elements,
  $('#cmd_move_select,#cmd_attack_select,' +
    '#cmd_dock_select,#cmd_mine_select').
      live('click', function(e){
        // just raise the corresponding event w/ content to display,
        // up to another component to take this and render it
        var cmd     = e.target.id;
        var cmds    = ship.selection[cmd];
        var title   = cmds[0];
        var content = cmds[1].apply(ship)
        ship.raise_event(cmd, ship, title, content);
      });

  // wire up command page elements
  $('#cmd_move').live('click', function(e){
    Commands.move_ship(ship,
                       $('#dest_x').val(),
                       $('#dest_y').val(),
                       $('#dest_z').val(),
                       function(res){
                         ship.raise_event('cmd_move', ship);
                       });
  })

  $('.cmd_attack').live('click', function(e){
    var eid = e.currentTarget.id.substr(11);
    var entity = Entities().get(eid);
    Commands.launch_attack(ship, entity,
                           function(res){
                             ship.raise_event('cmd_attack', ship, entity);
                           });
  })

  $('.cmd_dock').live('click', function(e){
    var eid = e.currentTarget.id.substr(9);
    var entity = Entities().get(eid);
    Commands.dock_ship(ship, entity,
                       function(res){
                         ship.update(res.result)
                         ship.raise_event('cmd_dock', ship, entity)
                       });
    $('#cmd_dock_select').hide();
    $('#cmd_undock').show();
    $('#cmd_transfer').show();
  })

  $('#cmd_undock').live('click', function(e){
    Commands.undock_ship(ship,
                         function(res){
                           ship.update(res.result)
                           ship.raise_event('cmd_undock', ship);
                         });
    $('#cmd_dock_select').show();
    $('#cmd_undock').hide();
    $('#cmd_transfer').hide();
  })

  $('#cmd_transfer').live('click', function(e){
    Commands.transfer_resources(ship, ship.docked_at_id,
                                function(res){
                                  if(!res.error){
                                    var sh = res.result[0];
                                    var st = res.result[1];
                                    ship.raise_event('cmd_transfer', sh, st);
                                  }
                                });
  })

  $('.cmd_mine').live('click', function(e){
    var rsid = e.currentTarget.id.substr(9);
    Commands.start_mining(ship, rsid,
                          function(res){
                            ship.raise_event('cmd_mine', ship, rsid);
                          });
  })

  // toggle selected
  this.selected = true;

  // refresh the ship
  this.refresh();

  // reload ship in scene
  scene.reload_entity(this);
}

/* Global ship timer helper
 * that checks for ship movement inbetween
 * notifications from server
 */
function _ship_movement_cycle(){
  var ships = Entities().select(function(e) {
    return e.json_class == 'Manufactured::Ship';
  });

  // FIXME how to synchronize timing between this and server?
  // TODO only ships in current scene

  for(var s = 0; s < ships.length; s++){
    var sh = ships[s];
    if(sh.location.movement_strategy.json_class ==
       'Motel::MovementStrategies::Linear'){
      var curr = new Date();
      if(sh.last_moved != null){
        var elapsed = curr - sh.last_moved;
        var dist = sh.location.movement_strategy.speed * elapsed / 1000;
        sh.location.x += sh.location.movement_strategy.dx * dist;
        sh.location.y += sh.location.movement_strategy.dy * dist;
        sh.location.z += sh.location.movement_strategy.dz * dist;
        sh.refresh();
      }
      sh.last_moved = curr;
    }else if(sh.location.movement_strategy.json_class ==
        'Motel::MovementStrategies::Rotate'){
      var curr = new Date();
      if(sh.last_moved != null){
        var elapsed = curr - sh.last_moved;
        var dist = sh.location.movement_strategy.rot_theta * elapsed / 1000;
        var new_or =
          rot(sh.location.orientation_x,
              sh.location.orientation_y,
              sh.location.orientation_z,
              dist,
              sh.location.movement_strategy.rot_x,
              sh.location.movement_strategy.rot_y,
              sh.location.movement_strategy.rot_z);
        sh.location.orientation_x = new_or[0];
        sh.location.orientation_y = new_or[1];
        sh.location.orientation_z = new_or[2];
        sh.refresh();
      }
      sh.last_moved = curr;
    }else{
      sh.last_moved = null;
    }
  }
}

Ship.run_timer = $.timer(function(){
  _ship_movement_cycle();
}, 150, false);
