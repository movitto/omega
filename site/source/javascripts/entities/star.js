/* Omega Javascript Star
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega Star
 */
function Star(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  var star = this;
  this.json_class = 'Cosmos::Entities::Star';

  // convert location
  this.location = new Location(this.location);

  // convert color
  this.icolor = parseInt('0x' + star.color);

  _star_load_mesh(this);
  _star_load_glow(this);
  _star_load_light(this);
  _star_load_flare(this);

  //this.added_to = function(scene){
  //   star.glow.material.uniforms.viewVector.value =
  //     new THREE.Vector3().subVectors( scene.camera._camera.position, star.glow.position );
  //}

  //star.clickable_obj = star.glow;
  this.shader_components.push(star.glow);
  this.shader_components.push(star.shader_sphere);
  this.components.push(star.sphere);
  this.components.push(star.light);
  //this.components.push(star.lensFlare);
}

/* Helper to load star mesh resources
 */
function _star_load_mesh(star){
  // instantiate sphere to draw star with on canvas
  var sphere_geometry =
    UIResources().cached('star_sphere_' + star.size + '_geometry',
      function(i) {
        var radius = star.size, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_texture =
    UIResources().cached("star_sphere_texture",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['star']['material'];
        return UIResources().load_texture(path);
      });

  var sphere_material =
    UIResources().cached("star_sphere_" + star.color + "_material",
      function(i) {
        /// FIXME resolve issue w/ poles: http://en.wikipedia.org/wiki/Hairy_ball_theorem
        /// https://github.com/AnalyticalGraphicsInc/cesium/pull/42
        var uniforms = {
          fogDensity: { type: "f", value: 0.0001 },
          fogColor: { type: "v3", value: new THREE.Vector3( 0, 0, 0 ) },
          time: { type: "f", value: 1.0 },
          resolution: { type: "v2", value: new THREE.Vector2(window.innerWidth, window.innerHeight) }, // XXX
          uvScale: { type: "v2", value: new THREE.Vector2( 2.0, 1.5 ) },
          texture1: { type: "t", value: UIResources().load_texture(UIResources().images_path + "/textures/lava/cloud.png" ) },
          texture2: { type: "t", value: UIResources().load_texture(UIResources().images_path + "/textures/lava/lavatile.jpg" ) }
        };

        uniforms.texture1.value.wrapS = uniforms.texture1.value.wrapT = THREE.RepeatWrapping;
        uniforms.texture2.value.wrapS = uniforms.texture2.value.wrapT = THREE.RepeatWrapping;
        //uniforms.texture1.value.repeat.set(20,20);

        return new THREE.ShaderMaterial({
          uniforms: uniforms,
          vertexShader: document.getElementById( 'vertexShaderLava' ).textContent,
          fragmentShader: document.getElementById( 'fragmentShaderLava' ).textContent
        });
      });

  star.sphere =
    UIResources().cached("star_" + star.id + "_sphere",
      function(i) {
        var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = star.location.x;
        sphere.position.y = star.location.y;
        sphere.position.z = star.location.z;

        var last = new Date();
        sphere.update_particles = function(){
          var now = new Date();
          var scale = 1;//Math.random() * 5;
          var delta = (now - last) * scale;
          sphere.material.uniforms.time.value += 0.0004 * delta;
          last = now;
        }

        return sphere;
      });

  star.shader_sphere =
    UIResources().cached("star_" + star.id + "_shader_sphere",
      function(i) {
        var sphere = new THREE.Mesh(sphere_geometry.clone(),
                                    new THREE.MeshBasicMaterial({color: 0x000000}));
        sphere.position.x = star.location.x;
        sphere.position.y = star.location.y;
        sphere.position.z = star.location.z;

        return sphere;
      });
}

/* Helper to load star glow resources
 */
function _star_load_glow(star){
  var glow_geometry =
    UIResources().get('star_sphere_' + star.size + '_geometry').clone();

  // TODO: shader doesn't incorporate depth, glow will appear over everything, need to fix
  var glow_texture = 
    UIResources().cached("star_glow_texture",
      function(i) {
        var vertex_shader   = document.getElementById( 'vertexShaderAtmosphere'   );
        var fragment_shader = document.getElementById( 'fragmentShaderAtmosphere' );
        vertex_shader   = vertex_shader   ? vertex_shader.textContent   : null;
        fragment_shader = fragment_shader ? fragment_shader.textContent : null;

        return new THREE.ShaderMaterial({
          uniforms: { 
            "c":   { type: "f", value: 0.2 },
            "p":   { type: "f", value: 4.0 },
            //glowColor: { type: "c", value: new THREE.Color(star.icolor) },
          },
          vertexShader: vertex_shader, fragmentShader: fragment_shader,
          side: THREE.BackSide
          //side: THREE.FrontSide, blending: THREE.AdditiveBlending,
          //transparent: true
        });
      });

  star.glow =
    UIResources().cached("star_" + star.id + "_glow",
      function(i) {
        var glow = new THREE.Mesh(glow_geometry, glow_texture);
        glow.scale.multiplyScalar(1.3);
        glow.position.x = star.location.x;
        glow.position.y = star.location.y;
        glow.position.z = star.location.z;
        return glow;
      });
}

/* Helper to load star light resources
 */
function _star_load_light(star){
  star.light =
    UIResources().cached("star_" + star.color + "_light",
      function(i) {
        var light = new THREE.PointLight(star.icolor, 1);
        light.position.set(0, 0, 0);
        return light;
      });
}

/* Helper to load star flare resources
 */
function _star_load_flare(star){
  var textureFlare0 =
    UIResources().load_texture(UIResources().images_path + "/textures/lensflare/lensflare0.png");
  var textureFlare2 =
    UIResources().load_texture(UIResources().images_path + "/textures/lensflare/lensflare2.png");
  var textureFlare3 =
    UIResources().load_texture(UIResources().images_path + "/textures/lensflare/lensflare3.png");
  var flareColor =
    new THREE.Color(star.icolor);

  star.lensFlare =
    new THREE.LensFlare(textureFlare0, 1000, 0.0,
                        THREE.AdditiveBlending, flareColor);

  star.lensFlare.add(textureFlare2, 512, 0.8, THREE.AdditiveBlending);
  star.lensFlare.add(textureFlare2, 512, 0.8, THREE.AdditiveBlending);
  star.lensFlare.add(textureFlare2, 512, 0.8, THREE.AdditiveBlending);
  star.lensFlare.add(textureFlare3, 120,  0.6, THREE.AdditiveBlending);
  star.lensFlare.add(textureFlare3, 240,  0.7, THREE.AdditiveBlending);
  star.lensFlare.add(textureFlare3, 240, 0.9, THREE.AdditiveBlending);
  star.lensFlare.add(textureFlare3, 140,  1.0, THREE.AdditiveBlending);

  star.lensFlare.customUpdateCallback = lensFlareUpdateCallback;
  star.lensFlare.position.set(star.location.x,
                              star.location.y + star.size/2,
                              star.location.z);
}

////////////////////////////// a few helper methods from three.js example
// http://threejs.org/examples/webgl_lensflares.html

function degToRad(){
	var degreeToRadiansFactor = Math.PI / 180;
	return function ( degrees ) {
		return degrees * degreeToRadiansFactor;
	};
}

function lensFlareUpdateCallback( object ) {
  var f, fl = object.lensFlares.length;
  var flare;
  var vecX = -object.positionScreen.x * 2;
  var vecY = -object.positionScreen.y * 2;

  for( f = 0; f < fl; f++ ) {
       flare = object.lensFlares[ f ];
       flare.x = object.positionScreen.x + vecX * flare.distance;
       flare.y = object.positionScreen.y + vecY * flare.distance;
       flare.rotation = 0;
  }

  object.lensFlares[ 2 ].y += 0.025;
  object.lensFlares[ 3 ].rotation = object.positionScreen.x * 0.5 + degToRad( 45 );
}
