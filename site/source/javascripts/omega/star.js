/* Omega Star JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Star = function(parameters){
  this.components        = [];
  this.shader_components = [];
  this.effects_timestamp = new Date();
  this.color             = 'FFFFFF';
  $.extend(this, parameters);

  this.color_int = parseInt('0x' + this.color);
  this.location = Omega.convert_entity(this.location)
};

Omega.Star.prototype = {
  constructor: Omega.Star,
  json_class : 'Cosmos::Entities::Star',

  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            color      : this.color,
            size       : this.size};
  },

  async_gfx : 2,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Star.gfx) !== 'undefined') return;
    Omega.Star.gfx = {};

    //// mesh
      // each star instance should override radius in the geometry instance
      var radius = 750, segments = 32, rings = 32;
      var mesh_geo = new THREE.SphereGeometry(radius, segments, rings);

      var texture_path = config.url_prefix + config.images_path + config.resources.star.texture;
      var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material     = new THREE.MeshBasicMaterial({map : texture});

      // each star instance should set position of their mesh instance
      Omega.Star.gfx.mesh = new THREE.Mesh(mesh_geo, material);

    /// glow
      var smesh_geo       = mesh_geo.clone();
      var vertex_shader   = Omega.get_shader('vertexShaderStar');
      var fragment_shader = Omega.get_shader('fragmentShaderStar');
      var shader = new THREE.ShaderMaterial({
        uniforms: {
          "c":   { type: "f", value: 0.4 },
          "p":   { type: "f", value: 2.0 },
        },
        vertexShader: vertex_shader,
        fragmentShader: fragment_shader,
        side: THREE.BackSide,
        blending: THREE.AdditiveBlending,
        transparent: true
      });
      Omega.Star.gfx.glow = new THREE.Mesh(smesh_geo, shader);
      Omega.Star.gfx.glow.scale.set(1.2, 1.2, 1.2);

    //// light
      // each star instance should set the color/position of their light instance
      var color = '0xFFFFFF';
      Omega.Star.gfx.light = new THREE.PointLight(color, 1);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized

    this.load_gfx(config, event_cb);

    this.mesh  = Omega.Star.gfx.mesh.clone();
    if(this.location) this.mesh.position.set(this.location.x, this.location.y, this.location.z);
    this.mesh.omega_entity = this;
    //mesh.geometry // TODO how to adjust radius?

    this.glow = Omega.Star.gfx.glow.clone();
    this.glow.position = this.mesh.position;
    this.glow.rotation = this.mesh.rotation;

    this.light = Omega.Star.gfx.light.clone();
    if(this.location) this.light.position.set(this.location.x, this.location.y, this.location.z);
    this.light.color.setHex(this.color_int);

    this.components = [this.glow, this.mesh, this.light];
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Star.prototype );
