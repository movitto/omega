/* Omega Galaxy Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_galaxy_gfx = function(config, event_cb){
  var gfx = {};
  Omega.Galaxy.gfx = gfx;

  gfx.density_wave = new Omega.GalaxyDensityWave(config, event_cb);
  //gfx.density_wave = new Omega.GalaxyDensityWave2(config, event_cb);
};

Omega.init_galaxy_gfx = function(config, galaxy, event_cb){
  galaxy.density_wave = Omega.Galaxy.gfx.density_wave.clone();
  galaxy.density_wave.sortParticles = true;
  galaxy.density_wave.position.set(0,0,0);
  galaxy.density_wave.rotation.set(1.57,0,0);
  galaxy.density_wave.omega_entity = galaxy;
  galaxy.components = [galaxy.density_wave];

  //galaxy.density_wave = Omega.Galaxy.gfx.density_wave;//.clone(); // TODO
  //galaxy.components = [galaxy.density_wave.mesh];
  //galaxy.clock = new THREE.Clock();
};

///////////////////////////////////////// initializers

Omega.load_galaxy_particles = function(config, event_cb){
  var particle_path = config.url_prefix + config.images_path + '/particle.png';
  return THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
};

Omega.GalaxyDensityWave = function(config, event_cb){
  var ptexture = Omega.load_galaxy_particles(config, event_cb);
  var material = new THREE.ParticleBasicMaterial({
    size: Omega.Galaxy.prototype.mesh_props.particle_size,
    vertexColors: true, transparent: true, depthWrite: false,
    map: ptexture, blending: THREE.AdditiveBlending
  });

  var geo       = new Omega.GalaxyDensityWaveGeometry();
  var particles = new THREE.ParticleSystem(geo, material);
  $.extend(this, particles);
};

/// Rotate a series of ellipses of increasing diameter
/// to form galaxy see density wave theory:
/// http://beltoforion.de/galaxy/galaxy_en.html#idRef3
Omega.GalaxyDensityWaveGeometry = function(){
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

      /// create color, modifying color & brightness based on distance
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

  $.extend(this, geo);
};

Omega.GalaxyDensityWave2 = function(config, event_cb){
  var particle_path = config.url_prefix + config.images_path + "/smokeparticle.png";
  var particleGroup = new ShaderParticleGroup({
    texture: THREE.ImageUtils.loadTexture(particle_path),
    maxAge: 2,
    blending: THREE.AdditiveBlending
  });

  var particleEmitter =
    new ShaderParticleEmitter({
      type: 'spiral',
      skew : 1.4,

      position: new THREE.Vector3(0, 0, 0),
      radius: 50,
      radiusSpread: 100,
      radiusScale: 10,
      speed: 0.5,
      colorStart: new THREE.Color('yellow'),
      colorEnd: new THREE.Color('red'),
      size: 50,
      //sizeSpread: 1,
      sizeEnd: 2,
      opacityStart: 1,
      opacityEnd: 1,
      particlesPerSecond: 5000,
      maxAge: 1000,
    });

  // Add the emitter to the group.
  particleGroup.addEmitter( particleEmitter );

  $.extend(this, particleGroup);
}

///////////////////////////////////////// other

/// Also gets mixed into the Galaxy Module
Omega.GalaxyEffectRunner = {
  /// TODO optimize (use particle engine
  run_effects : function(){
    var gmp = Omega.Galaxy.prototype.mesh_props;
    var geo = this.density_wave.geometry;
    for(var v = 0; v < geo.vertices.length; v++){
      /// get particle
      var vec = geo.vertices[v];
      var d = Omega.Math.dist(vec.x, vec.y, vec.z);

      /// calculate current theta
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

    geo.verticesNeedUpdate = true;
  },

  nrun_effects : function(){
    this.density_wave.tick(this.clock.getDelta());
  }
};
