$camera = {
  _camera : new THREE.PerspectiveCamera(75, 900 / 400, 1, 1000 ),
  //camera = new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);

  zoom : function(distance){
    var x = this._camera.position.x,
        y = this._camera.position.y,
        z = this._camera.position.z;
    var dist  = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    var phi = Math.atan2(x,z);
    var theta   = Math.acos(y/dist);

    if((dist + distance) <= 0) return;
    dist += distance;

    z = dist * Math.sin(theta) * Math.cos(phi);
    x = dist * Math.sin(theta) * Math.sin(phi);
    y = dist * Math.cos(theta);

    this._camera.position.x = x;
    this._camera.position.y = y;
    this._camera.position.z = z;

    this._camera.lookAt($scene._scene.position);
    $scene.animate();
  },

  rotate : function(theta_distance, phi_distance){
    var x = this._camera.position.x,
        y = this._camera.position.y,
        z = this._camera.position.z;
    var dist  = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    var phi = Math.atan2(x,z);
    var theta   = Math.acos(y/dist);
    if(z < 0) theta = 2 * Math.PI - theta; // adjust for acos loss

    theta += theta_distance;
    phi   += phi_distance;

    if(z < 0) theta = 2 * Math.PI - theta; // readjust for acos loss

    // prevent camera from going too far up / down
    if(theta < 0.5)
      theta = 0.5;
    else if(theta > (Math.PI - 0.5))
      theta = Math.PI - 0.5;

    z = dist * Math.sin(theta) * Math.cos(phi);
    x = dist * Math.sin(theta) * Math.sin(phi);
    y = dist * Math.cos(theta);

    this._camera.position.x = x;
    this._camera.position.y = y;
    this._camera.position.z = z;

    this._camera.lookAt($scene._scene.position);
    this._camera.updateMatrix();
    $scene.animate();
  }
}

$grid = {
  size : 250,
  step : 100,
  geometry : new THREE.Geometry(),
  material : new THREE.LineBasicMaterial( { color: 0xcccccc, opacity: 0.4 } ),

  init : function(){
    for ( var i = - this.size; i <= this.size; i += this.step ) {
      for ( var j = - this.size; j <= this.size; j += this.step ) {
        this.geometry.vertices.push( new THREE.Vector3( - this.size, j, i ) );
        this.geometry.vertices.push( new THREE.Vector3(   this.size, j, i ) );

        this.geometry.vertices.push( new THREE.Vector3( i, j, - this.size ) );
        this.geometry.vertices.push( new THREE.Vector3( i, j,   this.size ) );

        this.geometry.vertices.push( new THREE.Vector3( i, -this.size, j ) );
        this.geometry.vertices.push( new THREE.Vector3( i, this.size,  j ) );
      }
    }

    this.grid_line = new THREE.Line( this.geometry, this.material, THREE.LinePieces );
    this.showing_grid = false;
  },

  show : function(){
    $scene._scene.add( this.grid_line );
    this.showing_grid = true;
  },

  hide : function(){
    $scene._scene.remove(this.grid_line);
    this.showing_grid = false;
  },

  toggle : function(){
    var toggle_grid = $('#toggle_grid_canvas');
    if(toggle_grid){
      if(toggle_grid.is(':checked'))
        this.show();
      else
        this.hide();
    }
    $scene.animate();
  }
};

$scene = {
  init : function(){
    this._canvas   = $('#omega_canvas').get()[0];
    this._scene    = new THREE.Scene();
    this._renderer = new THREE.CanvasRenderer({canvas: this._canvas});
    this._renderer.setSize( 900, 400 );
    $camera._camera.position.z = 500;

    this.entities = {};

    // preload textures & other resources
    this.textures  = {jump_gate : THREE.ImageUtils.loadTexture("/womega/images/jump_gate.png")};
    this.materials = {line      : new THREE.LineBasicMaterial({color: 0xFFFFFF}),
                      system    : new THREE.MeshLambertMaterial({color: 0x996600, blending: THREE.AdditiveBlending}),
                      system_label : new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } ),
                      orbit : new THREE.LineBasicMaterial({color: 0xAAAAAA}),
                      moon : new THREE.MeshLambertMaterial({color: 0x808080, blending: THREE.AdditiveBlending}),
                      asteroid : new THREE.MeshBasicMaterial( { color: 0xffffff, overdraw: true }),
                      jump_gate : new THREE.MeshBasicMaterial( { map: $scene.textures['jump_gate'] } ),
                      jump_gate_selected : new THREE.MeshLambertMaterial({color: 0xffffff, transparent: true, opacity: 0.4}),
                      ship_surface : new THREE.LineBasicMaterial( { } ), // new THREE.MeshFaceMaterial({ });
                      ship_attacking : new THREE.LineBasicMaterial({color: 0xFF0000}),
                      ship_mining : new THREE.LineBasicMaterial({color: 0x0000FF}),
                      station_surface : new THREE.LineBasicMaterial( { } )
                      };
    // relatively new for three.js (mesh.doubleSided = true is old way):
    this.materials['jump_gate'].side = THREE.DoubleSide;
    this.materials['ship_surface'].side = THREE.DoubleSide;
    this.materials['station_surface'].side = THREE.DoubleSide;

    var mnradius = 5, mnsegments = 32, mnrings = 32;
    this.geometries = {asteroid : new THREE.TextGeometry( "*", {height: 20, curveSegments: 2, font: 'helvetiker', size: 32}),
                       moon     : new THREE.SphereGeometry(mnradius, mnsegments, mnrings),};

    return this;
  },

  has : function(entity){
    return this.entities[entity.id] != null;
  },

  add : function(entity){
    load_entity(entity);
    this.entities[entity.id] = entity;
  },

  remove : function(entity_id){
    var entity = this.entities[entity_id];
    for(var scene_entity in entity.scene_objs){
      var se = entity.scene_objs[scene_entity];
      this._scene.remove(se);
      delete entity.scene_objs[scene_entity];
    }
    this.entities[entity_id].scene_objs = [];
    delete this.entities[entity_id];
  },

  reload : function(entity){
    this.remove(entity.id);
    this.add(entity);
    this.animate();
  },

  clear : function(){
    for(var entity in this.entities){
      entity = this.entities[entity]
      for(var scene_entity in entity.scene_objs){
        var se = entity.scene_objs[scene_entity];
        this._scene.remove(se);
        delete entity.scene_objs[scene_entity];
      }
      this.entities[entity.id].scene_objs = [];
      delete this.entities[entity.id];
    }
    this.entities = [];
  },

  animate : function(){
    requestAnimationFrame(this.render);
  },

  render : function(){
    $scene._renderer.render($scene._scene, $camera._camera);
  }

}

//////////////////////////////////////////////////////////

$(document).ready(function(){ 
  $grid.init();
  $scene.init().animate();
});
