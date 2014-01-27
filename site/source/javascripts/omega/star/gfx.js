/* Omega Star Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_star_gfx = function(config, event_cb){
  var gfx = {};

  gfx.mesh  = new Omega.StarMesh(config, event_cb);
  gfx.glow  = new Omega.StarGlow();
  gfx.light = new Omega.StarLight();

  Omega.Star.gfx = gfx;
};

Omega.init_star_gfx = function(config, star, event_cb){
  star.mesh = Omega.Star.gfx.mesh.clone();
  star.mesh.omega_entity = star;
  /// TODO scale mesh to match star radius
  if(star.location)
    star.mesh.position.set(star.location.x,
                           star.location.y,
                           star.location.z);

  star.glow = Omega.Star.gfx.glow.clone();
  star.glow.position = star.mesh.position;
  star.glow.rotation = star.mesh.rotation;

  star.light = Omega.Star.gfx.light.clone();
  star.light.position = star.mesh.position;
  star.light.color.setHex(star.color_int);

  star.components = [star.glow, star.mesh, star.light];
};

///////////////////////////////////////// initializers

Omega.load_star_geometry = function(){
  /// each star instance should override radius in the geometry instance
  var radius = 750, segments = 32, rings = 32;
  return new THREE.SphereGeometry(radius, segments, rings);
}

Omega.StarMesh = function(config, event_cb){
  var mesh_geo     = Omega.load_star_geometry();
  var texture_path = config.url_prefix + config.images_path +
                     config.resources.star.texture;
  var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  var material     = new THREE.MeshBasicMaterial({map : texture});

  var mesh = new THREE.Mesh(mesh_geo, material);
  $.extend(this, mesh);
};

Omega.StarGlow = function(){
  var smesh_geo       = Omega.load_star_geometry();
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

  var glow = new THREE.Mesh(smesh_geo, shader);
  glow.scale.set(1.2, 1.2, 1.2);
  $.extend(this, glow);
};

Omega.StarLight = function(){
  // each star instance should set the color/position of their light instance
  var color = '0xFFFFFF';
  var light = new THREE.PointLight(color, 1);
  $.extend(this, light);
};
