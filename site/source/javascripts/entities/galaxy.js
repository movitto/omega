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

  // instantiate mesh to draw galaxy on canvas
  _galaxy_load_mesh(this);

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

/* Helper method to load galaxy mesh resources
 */
var galaxy_mesh_props = {
  particle_size : 30,
  eskew         : 1.2,
  estart        : 1,
  eend          : 1000,
  einc          : 15,
  itinc         : 0.05,
  utinc         : 0.02,
  max_z         : 150
}

function _galaxy_load_mesh(galaxy){
  // rotate a series of ellipses of increasing diameter to form galaxy
  var mat =
    UIResources().cached("galaxy_" + galaxy.id + "_material",
      function(){
        return new THREE.ParticleBasicMaterial({size: galaxy_mesh_props.particle_size,
                   vertexColors: true,
                   map: UIResources().load_texture(UIResources().images_path + "/particle.png"),
                   blending: THREE.AdditiveBlending,
                   transparent: true });
      });

  /// http://beltoforion.de/galaxy/galaxy_en.html#idRef3
  var geo =
    UIResources().cached("galaxy_" + galaxy.id + "_geometry",
      function(){
        var gmp = galaxy_mesh_props;
        var geo = new THREE.Geometry();
        var ecurr_rot = 0;

        // reset vertices/colors
        geo.colors   = [];
        geo.vertices = [];

        for(var s = gmp.estart; s < gmp.eend; s += gmp.einc) {
          for(var t = 0; t < 2*Math.PI; t += gmp.itinc){
            // ellipse
            var x = s * Math.sin(t)
            var y = s * Math.cos(t) * gmp.eskew;

            // rotate
            var n = rot(x,y,0,ecurr_rot,0,0,1);

            var x1 = n[0]; var y1 = n[1];
            var d  = Math.sqrt(Math.pow(x1,2)+Math.pow(y1,2))

            // create position vertex
            var pv = new THREE.Vector3(x1, y1, 0);
            pv.ellipse = [s,ecurr_rot];
            geo.vertices.push(pv);

            // randomize z position in bulge
            if(d<100) pv.z = Math.floor(Math.random() * 100);
            else      pv.z = Math.floor(Math.random() * gmp.max_z / d*100);

            if(d > 500) pv.z /= 2;
            else if(d > 1500) pv.z /= 3;
            if(Math.floor(Math.random() * 2) == 0) pv.z *= -1;

            // create color, modifing color & brightness based on distance
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
      });

  var mesh =
    UIResources().cached("galaxy_" + galaxy.id + "_mesh",
      function(){
        var mesh = new THREE.ParticleSystem(geo, mat);
        mesh.sortParticles = true;
        mesh.position.set(0,0,0);
        mesh.rotation.set(1.57,0,0)
        return mesh;
      });

  mesh.update_particles = _update_galaxy_mesh;
  //window.setInterval(function(){update_galaxy.apply(mesh,[])},250)
  galaxy.mesh = mesh;
}

function _update_galaxy_mesh(){
  for(var v = 0; v < this.geometry.vertices.length; v++){
    /// get particle
    var vec = this.geometry.vertices[v];
    var d = Math.sqrt(Math.pow(vec.x,2)+Math.pow(vec.y,2)+Math.pow(vec.z,2));

    /// calculate current theta
    var s = vec.ellipse[0]; var rote = vec.ellipse[1];
    var o = rot(vec.x,vec.y,vec.z,-rote,0,0,1);
    var t = Math.asin(o[0]/s);
    if(o[1] < 0) t = Math.PI - t;

    /// rotate it along its elliptical path
        t+= galaxy_mesh_props.utinc/d*100;
    var x = s * Math.sin(t);
    var y = s * Math.cos(t) * galaxy_mesh_props.eskew;
    var n = rot(x,y,o[2],rote,0,0,1)

    /// set particle
    vec.set(n[0], n[1], n[2]);
  }

  this.geometry.__dirtyVertices = true;
}
