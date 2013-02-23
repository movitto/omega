/* Omega Rendering Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/vendor/three.js');
require('javascripts/vendor/helvetiker_font/helvetiker_regular.typeface.js');

/////////////////////////////////////// Omega Scene Selection

/* Initialize new Omega Selection
 */
function OmegaSelection(){
  /////////////////////////////////////// private data

  var selected_entities   =   [];

  /////////////////////////////////////// public methods

  /* Return boolean indicating if entity specified by id
   * is currently selected
   */
  this.is_selected = function(entity_id){
    for(var se in selected_entities){
      if(selected_entities[se] == entity_id)
        return true;
    }

    return false;
  }

  /* Select entity specified by id
   */
  this.select = function(entity_id){
    if(this.is_selected(entity_id))
      return;
    selected_entities.push(entity_id);
  }

  /* Unselect entity specified by id
   */
  this.unselect = function(entity_id){
    for(var index in selected_entities){
      if(selected_entities[index] == entity_id){
        selected_entities.splice(index, 1);
        return;
      }
    }
  }

  /* Return the first selected item entity
   *
   * XXX might not be best to expose a 'single' selection, but works for now
   */
  this.selected = function(){
    return selected_entities[0];
  }
}


/////////////////////////////////////// Omega Canvas Scene

/* Initialize new Omega Scene
 */
function OmegaScene(){
  /////////////////////////////////////// private data

  var _canvas   = $('#omega_canvas').get()[0];

  var _scene    = new THREE.Scene();

  //var _renderer = new THREE.CanvasRenderer({canvas: _canvas});
  var _renderer = new THREE.WebGLRenderer();

  _renderer.setSize( 900, 400 );
  $('#omega_canvas').append(_renderer.domElement);

  var entities = {};

  var scene_changed_callbacks = {};

  var root_entity    = null;

  /////////////////////////////////////// public data

  this.selection  = new OmegaSelection();

  /////////////////////////////////////// public (read-only) data

  // preload textures & other resources
  this.textures   = {jump_gate : THREE.ImageUtils.loadTexture("/womega/images/textures/jump_gate.jpg"),
                     star      : THREE.ImageUtils.loadTexture("/womega/images/textures/greensun.jpg"),
                     solar_system : THREE.ImageUtils.loadTexture("/womega/images/solar_system.png")};
  this.materials = {line      : new THREE.LineBasicMaterial({color: 0xFFFFFF}),
                    system_sphere : new THREE.MeshBasicMaterial({color: 0x996600, opacity: 0.2}),
                    system_plane  : new THREE.MeshBasicMaterial({map: this.textures['solar_system']}),
                    system_label : new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } ),
                    orbit : new THREE.LineBasicMaterial({color: 0xAAAAAA}),
                    moon : new THREE.MeshBasicMaterial({color: 0x808080}),
                    asteroid : new THREE.MeshBasicMaterial( { color: 0x666600, wireframe: false }),
                    asteroid_container : new THREE.MeshBasicMaterial( { opacity: 0.0, transparent: true } ),
                    jump_gate : new THREE.MeshBasicMaterial( { map: this.textures['jump_gate'] } ),
                    jump_gate_selected : new THREE.MeshBasicMaterial({color: 0xffffff, transparent: true, opacity: 0.4}),
                    ship_attacking : new THREE.LineBasicMaterial({color: 0xFF0000}),
                    ship_mining : new THREE.LineBasicMaterial({color: 0x0000FF})
                   };
  // relatively new for three.js (mesh.doubleSided = true is old way):
  this.materials['system_plane'].side       = THREE.DoubleSide;

  this.textures['jump_gate'].wrapS  = THREE.RepeatWrapping;
  this.textures['jump_gate'].wrapT  = THREE.RepeatWrapping;
  this.textures['jump_gate'].repeat.x  = 5;
  this.textures['jump_gate'].repeat.y  = 5;

  var astradius = 25, astsegments = 32, astrings = 32;
  var mnradius = 5, mnsegments = 32, mnrings = 32;
  this.geometries = {moon     : new THREE.SphereGeometry(mnradius, mnsegments, mnrings),
                     asteroid_container : new THREE.SphereGeometry(astradius, astsegments, astrings),
                     ship     : null, station : null, asteroid : null, jump_gate : null};

  var loader = new THREE.JSONLoader();
  loader.load('images/meshes/brigantine.js', function(geometry){
    geometry.computeTangents();
    $omega_scene.geometries['ship'] = geometry;
  });
  loader.load('images/meshes/research.js', function(geometry){
    geometry.computeTangents();
    $omega_scene.geometries['station'] = geometry;
  });
  loader.load('images/meshes/asteroids1.js', function(geometry){
    geometry.computeTangents();
    $omega_scene.geometries['asteroid'] = geometry;
  });
  loader.load('images/meshes/jump_gate.js', function(geometry){
    geometry.computeTangents();
    $omega_scene.geometries['jump_gate'] = geometry;
  });

  /////////////////////////////////////// private methods

  /////////////////////////////////////// public methods

  /* Clear all entities tracked by scene
   */
  this.clear = function(){
    for(var entity in entities){
      entity = entities[entity]
      for(var scene_entity in entity.scene_objs){
        var se = entity.scene_objs[scene_entity];
        _scene.remove(se);
        delete entity.scene_objs[scene_entity];
      }
      entities[entity.id].scene_objs = [];
      delete entities[entity.id];
    }
    entities = [];
  }


  /* Clear all scene changed callbacks
   */
  this.clear_callbacks = function(){
    scene_changed_callbacks = {};
  }

  /* Register callback to be invoked on scene change.
   *
   * A callback id should be specified to track the callback,
   * overwriting a previously assigned callback w/ the same id
   */
  this.on_scene_change = function(callback_id, callback){
    scene_changed_callbacks[callback_id] = callback;
  }

  /* Set root entity of the scene.
   *
   * Children will be iterated over and added to scene one by one.
   * Scene changed callbacks will be invoked and scene animated
   */
  this.set_root = function(entity){
    root_entity = entity;
    $omega_skybox.set_background(entity);
    $omega_entity_container.hide();

    this.clear();

    // load the accessible entities under the root
    // TODO should apply to systems only
    OmegaQuery.entities_under(root_entity.name, function(entities){
      for(var e in entities){
        var entity = entities[e];
        if(!$omega_scene.has(entity)){
          $omega_scene.add_entity(entity);
          if(entity.added_to_scene)
            entity.added_to_scene();
        }
      }
    });

    // load all children under the root
    var children = entity.children();
    for(var child in children){
      child = children[child];
      if(child){
        this.add_entity(child);
        if(child.added_to_scene)
          child.added_to_scene();
      }
    }

    // XXX hack hide dialog
    if(typeof $omega_dialog !== "undefined") $omega_dialog.hide();

    // invoke registered scene changed callbacks
    for(var cb in scene_changed_callbacks)
      scene_changed_callbacks[cb]();

    // animate the scene
    this.animate();
  }

  /* Return root entity of the scene
   */
  this.get_root = function(){
    return root_entity;
  }

  /* Refresh entities in the current scene
   */
  this.refresh = function(){
    this.set_root(root_entity);
  }

  /* Return boolean indicating in current scene
   * has the specified entity
   */
  this.has = function(entity){
    return entities[entity.id] != null;
  }

  /* Add specified entity to scene
   */
  this.add_entity = function(entity){
    entity.load();
    entities[entity.id] = entity;
  }

  /* Add specified scene object to backend three.js scene
   *
   * XXX would like to remove this or mark private
   */
  this.add = function(scene_obj){
    _scene.add(scene_obj);
  }
  
  /* Remove specified scene object from backend three.js scene
   *
   * XXX would like to remove this or mark private
   */
  this.remove_obj = function(scene_obj){
    _scene.remove(scene_obj);
  }

  /* Remove the entity specifed by entity_id from the scene.
   *
   * Will delete all scene objects corresponding to entity
   */
  this.remove = function(entity_id){
    var entity = entities[entity_id];
    if(entity == null)
      return;

    for(var scene_entity in entity.scene_objs){
      var se = entity.scene_objs[scene_entity];
      _scene.remove(se);
      delete entity.scene_objs[scene_entity];
    }
    entities[entity_id].scene_objs = [];
    delete entities[entity_id];
  }

  /* Manually reload the specified entity in the scene.
   *
   * Removes it and readds if appropriate before animating scene
   */
  this.reload = function(entity){
    // remove entity from scene
    this.remove(entity.id);

    // add entity to scene if parent location
    // corresponds to scene root
    if(root_entity &&
       entity.location.parent_id == root_entity.location.id)
      this.add_entity(entity);

    // reanimate scene
    this.animate();
  }


  /* Request animation frame
   */
  this.animate = function(){
    requestAnimationFrame(this.render);
  }

  /* Internal helper to render scene.
   *
   * !private shouldn't be called by end user!
   */
  this.render = function(){
    if(typeof($omega_camera) !== "undefined") // XXX hack shouldn't need conditional
      _renderer.render(_scene, $omega_camera.scene_camera());
  }

  /* Return the position of the backend scene
   *
   * XXX camera requries access to scene position
   */
  this.position = function(){
    return _scene.position;
  }

  /* Return all scene objects in the scene
   *
   * XXX canvas clicked handler request access to scene objects
   */
  this.scene_objects = function(){
    return _scene.__objects;
  }

  /* Return all entities in the scene
   *
   * XXX canvas clicked handler requires scene entities
   */
  this.entities = function(){
    return entities;
  }
}
