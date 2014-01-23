/* Omega Solar System Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_solar_system_gfx = function(config, event_cb){
  var gfx = {};
  Omega.SolarSystem.gfx = gfx;

  gfx.mesh  = new Omega.SolarSystemMesh();
  gfx.plane = new Omega.SolarSystemPlane(config, event_cb);

  gfx.text_material      = new THREE.MeshBasicMaterial({ color: 0x3366FF,
                                                         overdraw: true  });
  gfx.interconn_material = new THREE.LineBasicMaterial({ color: 0xF80000 });
  gfx.interconn_particle_material =
    new Omega.load_solar_system_interconn_material(config, event_cb);
};

Omega.init_solar_system_gfx = function(config, solar_system, event_cb){
  solar_system.mesh = Omega.SolarSystem.gfx.mesh.clone();
  solar_system.mesh.omega_entity = solar_system;
  if(solar_system.location)
    solar_system.mesh.position.set(solar_system.location.x,
                                   solar_system.location.y,
                                   solar_system.location.z);

  solar_system.plane = Omega.SolarSystem.gfx.plane.clone();
  if(solar_system.location)
    solar_system.plane.position.set(solar_system.location.x,
                                    solar_system.location.y,
                                    solar_system.location.z);

  /// text geometry needs to be created on system by system basis
  var text_geo = new THREE.TextGeometry(solar_system.name, Omega.SolarSystem.prototype.text_opts);
  THREE.GeometryUtils.center(text_geo);
  solar_system.text    = new THREE.Mesh(text_geo, Omega.SolarSystem.gfx.text_material);
  if(solar_system.location)
    solar_system.text.position.set(solar_system.location.x,
                                   solar_system.location.y + 50,
                                   solar_system.location.z);

  /// TODO only display sphere on mouse over
  solar_system.components =
    [solar_system.mesh, solar_system.plane, solar_system.text];

  if(solar_system._queued_interconns){
    for(var i = 0; i < solar_system._queued_interconns.length; i++){
      solar_system.add_interconn(solar_system._queued_interconns[i]);
    }
    solar_system._queued_interconns = null;
  }
};

///////////////////////////////////////// initializers

Omega.SolarSystemMesh = function(){
  var radius = 50, segments = 32, rings = 32;
  var geo = new THREE.SphereGeometry(radius, segments, rings);
  var mat = new THREE.MeshBasicMaterial({opacity: 0.2, transparent: true});
  $.extend(this, new THREE.Mesh(geo, mat));
}

Omega.SolarSystemPlane = function(config, event_cb){
  var plane = new THREE.PlaneGeometry(100, 100);
  var texture_path = config.url_prefix + config.images_path +
                     config.resources.solar_system.material;
  var texture  = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  var material =
    new THREE.MeshBasicMaterial({map: texture,
                                 alphaTest: 0.5});

  material.side = THREE.DoubleSide;
  $.extend(this, new THREE.Mesh(plane, material));
  this.rotation.x = 1.57;
}

Omega.add_solar_system_interconn = function(solar_system, endpoint){
  if(solar_system.components.length == 0){
    if(!solar_system._queued_interconns)
      solar_system._queued_interconns = [];
    solar_system._queued_interconns.push(endpoint);
    return;
  }

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(solar_system.location.x,
                                           solar_system.location.y,
                                           solar_system.location.z));
  geometry.vertices.push(new THREE.Vector3(endpoint.location.x,
                                           endpoint.location.y,
                                           endpoint.location.z));
  var line = new THREE.Line(geometry, Omega.SolarSystem.gfx.interconn_material);
  solar_system.components.push(line);

  /// TODO use particle engine for this
  var particle_geo = new THREE.Geometry();
  particle_geo.vertices.push(new THREE.Vector3(0,0,0));
  var particle_system = new THREE.ParticleSystem(particle_geo,
            Omega.SolarSystem.gfx.interconn_particle_material);
  particle_system.position.set(solar_system.location.x,
                               solar_system.location.y,
                               solar_system.location.z);

  var d = solar_system.location.distance_from(endpoint.location);
  var dx = (endpoint.location.x - solar_system.location.x) / d;
  var dy = (endpoint.location.y - solar_system.location.y) / d;
  var dz = (endpoint.location.z - solar_system.location.z) / d;

  particle_system.sortParticles = true;
  particle_system.ticker = 0;
  particle_system.ticks = d / 50;
  particle_system.dx = dx;
  particle_system.dy = dy;
  particle_system.dz = dz;

  solar_system.components.push(particle_system);
  solar_system.interconnections.push(particle_system);
};

Omega.load_solar_system_interconn_material = function(config, event_cb){
  var texture_path = config.url_prefix + config.images_path + '/particle.png';
  var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  var mat =
    new THREE.ParticleBasicMaterial({
      color: 0xFF0000, size: 50, transparent: true , depthWrite: false,
      map: texture, blending: THREE.AdditiveBlending
    });
  return mat;
};

///////////////////////////////////////// other

/// Also gets mixed into the SolarSystem Module
Omega.SolarSystemEffectRunner = {
  run_effects : function(){
    for(var i = 0; i < this.interconnections.length; i++){
      var interconn = this.interconnections[i];
      var v         = interconn.geometry.vertices[0];

      v.set(interconn.ticker * interconn.dx * 50,
            interconn.ticker * interconn.dy * 50,
            interconn.ticker * interconn.dz * 50)

      interconn.ticker += 1;
      if(interconn.ticker >= interconn.ticks)
        interconn.ticker = 0;
      interconn.geometry.verticesNeedUpdate = true;
    }
  }
};
