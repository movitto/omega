/* Omega Galaxy JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Galaxy = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.children   = [];
  $.extend(this, parameters);

  this.bg = Omega.str_to_bg(this.id);

  this.children = Omega.convert_entities(this.children);
  this.location = Omega.convert_entity(this.location)
};

Omega.Galaxy.prototype = {
  constructor : Omega.Galaxy,
  json_class  : 'Cosmos::Entities::Galaxy',

  toJSON : function(){
    var children_json = [];
    for(var c = 0; c < this.children.length; c++)
      children_json.push(this.children[c].toJSON())

    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            children   : children_json};
  },

  systems : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::SolarSystem';
    });
  },

  set_children_from : function(entities){
    var systems = this.children;
    for(var s = 0; s < systems.length; s++){
      var system = $.grep(entities, function(entity){
        return entity.id == systems[s].id;
      })[0];

      if(system != null){
        this.children[s] = system;
        system.galaxy = this;
      }
    }
  },

  mesh_props  : {
    particle_size : 150,
    eskew         : 1.2,
    estart        : 1,
    eend          : 2000,
    einc          : 30,
    itinc         : 0.15,
    utinc         : 0.03,
    max_z         : 150
  },

  /// rotate a series of ellipses of increasing diameter to form galaxy
  /// see density wave theory:
  /// http://beltoforion.de/galaxy/galaxy_en.html#idRef3
  _load_density_wave : function(){
    var gmp = Omega.Galaxy.prototype.mesh_props;
    var geo = new THREE.Geometry();
    var ecurr_rot = 0;

    /// reset vertices/colors
    geo.colors   = [];
    geo.vertices = [];

    for(var s = gmp.estart; s < gmp.eend; s += gmp.einc) {
      for(var t = 0; t < 2*Math.PI; t += gmp.itinc){
        /// ellipse
        var x = s * Math.sin(t)
        var y = s * Math.cos(t) * gmp.eskew;

        /// rotate
        var n = Omega.Math.rot(x,y,0,ecurr_rot,0,0,1);

        var x1 = n[0]; var y1 = n[1];
        var d  = Math.sqrt(Math.pow(x1,2)+Math.pow(y1,2))

        /// create position vertex
        var pv = new THREE.Vector3(x1, y1, 0);
        pv.ellipse = [s,ecurr_rot];
        geo.vertices.push(pv);

        /// randomize z position in bulge
        if(d<100) pv.z = Math.floor(Math.random() * 100);
        else      pv.z = Math.floor(Math.random() * gmp.max_z / d*100);

        if(d > 500) pv.z /= 2;
        else if(d > 1500) pv.z /= 3;
        if(Math.floor(Math.random() * 2) == 0) pv.z *= -1;

        /// create color, modifing color & brightness based on distance
        var ifa = Math.floor(Math.random() * 15 - (Math.exp(-d/4000) * 5));// 1/2 intensity distance: 4000
        var pc = 0xFFFFFF;
        if(Math.floor(Math.random() * 5) != 0){ // 1/5 particles are white
          if(d > gmp.eend/5)
            pc = 0x000DCC;                      // stars far from the center are blue
          else{
            if(Math.floor(Math.random() * 5) != 0){
              var n = Math.floor(Math.random() * 4);
              if(n == 0)
                pc = 0xFF6600;
              else if(n == 1)
                pc = 0xFFCC00;
              else if(n == 2)
                pc = 0xFF0033;
              else if(n == 3)
                pc = 0xCC9900;
            }
          }
        }

        for(var i=0; i < ifa; i++)
          pc = ((pc & 0xfefefe) >> 1);

        geo.colors.push(new THREE.Color(pc));
      }
      ecurr_rot += 0.1;
    }

    return geo;
  },

  async_gfx : 1,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Galaxy.gfx) !== 'undefined') return;
    Omega.Galaxy.gfx = {};

    /// particle system
      var texture_path = config.url_prefix + config.images_path + "/particle.png";
      var texture  = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);

      var material = new THREE.ParticleBasicMaterial({
        size: Omega.Galaxy.prototype.mesh_props.particle_size,
        vertexColors: true, transparent: true,
        map: texture, blending: THREE.AdditiveBlending
      });

      var geo = this._load_density_wave();
      var particles = new THREE.ParticleSystem(geo, material);
      Omega.Galaxy.gfx.particles = particles;
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.particles  = Omega.Galaxy.gfx.particles.clone();
    this.particles.sortParticles = true;
    this.particles.position.set(0,0,0);
    this.particles.rotation.set(1.57,0,0);
    this.particles.omega_entity = this;

    this.components = [this.particles];
  },

  /// TODO optimize
  run_effects : function(){
    var gmp = Omega.Galaxy.prototype.mesh_props;
    var geo = this.particles.geometry;
    for(var v = 0; v < geo.vertices.length; v++){
      /// get particle
      var vec = geo.vertices[v];
      var d = Omega.Math.dist(vec.x, vec.y, vec.z);

      /// calculate current theta
/// FIXME ellipse property prolly won't be cloned
      var s = vec.ellipse[0]; var rote = vec.ellipse[1];
      var o = Omega.Math.rot(vec.x,vec.y,vec.z,-rote,0,0,1);
      var t = Math.asin(o[0]/s);
      if(o[1] < 0) t = Math.PI - t;

      /// rotate it along its elliptical path
          t+= gmp.utinc/d*100;
      var x = s * Math.sin(t);
      var y = s * Math.cos(t) * gmp.eskew;
      var n = Omega.Math.rot(x,y,o[2],rote,0,0,1)

      /// set particle
      vec.set(n[0], n[1], n[2]);
    }

    geo.__dirtyVertices = true;
  }
};

// return the galaxy with the specified id
Omega.Galaxy.with_id = function(id, node, cb){
  node.http_invoke('cosmos::get_entity',
    'with_id', id,
    function(response){
      var galaxy = null;
      if(response.result) galaxy = new Omega.Galaxy(response.result);
      cb(galaxy);
    });
};

THREE.EventDispatcher.prototype.apply( Omega.Galaxy.prototype );
