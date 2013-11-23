/* Omega SolarSystem JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystem = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.children   = [];
  this.background = '';
  $.extend(this, parameters);

  this.bg = 'system' + this.background;
  this.children = Omega.convert_entities(this.children);
};

Omega.SolarSystem.prototype = {
  json_class : 'Cosmos::Entities::SolarSystem',

  text_opts : {
    height        : 12,
    width         : 5,
    curveSegments : 2,
    font          : 'helvetiker',
    size          : 48
  },

  load_gfx : function(config, event_cb){
    if(typeof(Omega.SolarSystem.gfx) !== 'undefined') return;
    Omega.SolarSystem.gfx = {};

    /// mesh
      /// each solar system instance should set mesh position
      var radius = 50, segments = 32, rings = 32;
      var geo    = new THREE.SphereGeometry(radius, segments, rings);
      var mat    = new THREE.MeshBasicMaterial({opacity: 0, transparent: true});
      Omega.SolarSystem.gfx.mesh = new THREE.Mesh(geo, mat);

    /// plane
      /// each solar system instance should set plane position
      var plane = new THREE.PlaneGeometry(100, 100);
      var texture_path = config.url_prefix + config.images_path + config.resources.solar_system.material;
      var texture  = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material =
        new THREE.MeshBasicMaterial({map: texture,
                                     alphaTest: 0.5});

      material.side = THREE.DoubleSide;
      Omega.SolarSystem.gfx.plane = new THREE.Mesh(plane, material);

    /// text
      Omega.SolarSystem.gfx.text_material = new THREE.MeshBasicMaterial({ color: 0x3366FF, overdraw: true });
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.mesh = Omega.SolarSystem.gfx.mesh.clone();
    this.mesh.omega_entity = this;
    if(this.location) this.mesh.position.set(this.location.x, this.location.y, this.location.z);

    this.plane = Omega.SolarSystem.gfx.plane.clone();
    if(this.location) this.plane.position.set(this.location.x, this.location.y, this.location.z);

    /// text geometry needs to be created on system by system basis
    var text_geo = new THREE.TextGeometry(this.name, Omega.SolarSystem.prototype.text_opts);
    this.text    = new THREE.Mesh(text_geo, Omega.SolarSystem.gfx.text_material);
    if(this.location) this.text.position.set(this.location.x, this.location.y, this.location.z - 50);
  },

  run_effects : function(){
    /// TODO run jump gate line effects
  },

  add_jump_gate : function(jg){
    /// TODO
  }
};

// return the solar system with the specified id
Omega.SolarSystem.with_id = function(id, node, cb){
  node.http_invoke('cosmos::get_entity',
    'with_id', id,
    function(response){
      var sys = null;
      if(response.result) sys = new Omega.SolarSystem(response.result);
      cb(sys);
    });
}
