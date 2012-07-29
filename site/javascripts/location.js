function Location(){
  this.id = null;
  this.x = 0;
  this.y = 0;
  this.z = 0;

  // entities rendered to the scene
  this.scene_entities = [];

  // if this location is 'dirty' and show be redrawn
  this.dirty = true;

  this.size = 0;
  this.parent_id = null;
  this.movement_strategy = null;
  this.entity = null;
  if(typeof canvas_ui != 'undefined') this.draw    = canvas_ui.draw_nothing;
  if(typeof controls != 'undefined') this.clicked = controls.unregistered_click;

  this.update = function(new_location){
    this.id = new_location.id;
    this.x = new_location.x;
    this.y = new_location.y;
    this.z = new_location.z;
    this.dirty = true;

    if(new_location.movement_strategy)
      this.movement_strategy = new_location.movement_strategy;

    if(new_location.entity)
      this.entity = new_location.entity;

    if(new_location.parent_id)
      this.parent_id = new_location.parent_id;

    if(this.entity)
      this.entity.location = this;
  };

  this.no_setup = function(scene){
    for(var scene_entity in this.scene_entities){
      scene.remove(this.scene_entities[scene_entity]);
    }
    this.scene_entities = [];
    this.dirty = true;
  }
  this.setup_if_dirty = function(scene){
    if(this.dirty){
      for(var scene_entity in this.scene_entities){
        scene.remove(this.scene_entities[scene_entity]);
      }
      this.scene_entities = [];
      this.draw(this.entity);
    }
    this.dirty = false;
  };
  this.setup_in_scene = this.no_setup;

  this.within_distance = function(x, y, z, distance){
    return Math.sqrt(Math.pow(this.x - x, 2) + Math.pow(this.y - y, 2) + Math.pow(this.z - z, 2)) < distance;
  };

  this.to_s = function() { return (Math.round(this.x*100)/100) + "," +
                                  (Math.round(this.y*100)/100) + "," +
                                  (Math.round(this.z*100)/100); }

  this.toJSON = function(){ return new JRObject("Motel::Location", this, 
                                                ["toJSON", "entity", "movement_strategy", "notifications"]).toJSON(); };
  //JRObject.class_registry['Motel::Location'] = Location;
};
