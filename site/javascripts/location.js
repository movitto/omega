function Location(){
  this.id = null;
  this.x = 0;
  this.y = 0;
  this.z = 0;

  // x,y,z coordinates projected into camera viewspace
  this.cx = 0;
  this.cy = 0;
  this.cz = 0;

  this.size = 0;
  this.parent_id = null;
  this.movement_strategy = null;
  this.entity = null;
  if(typeof ui != 'undefined') this.draw    = ui.draw_nothing;
  if(typeof controls != 'undefined') this.clicked = controls.unregistered_click;

  this.update = function(new_location){
    this.id = new_location.id;
    this.x = new_location.x;
    this.y = new_location.y;
    this.z = new_location.z;

    if(new_location.movement_strategy)
      this.movement_strategy = new_location.movement_strategy;

    // needs to be invoked after movement stategy is set as orbit is updated here
    if(ui.camera){
      var nloc = ui.camera.update_location(this);
      this.cx = nloc.cx; this.cy = nloc.cy; this.cz = nloc.cz;
    }

    if(new_location.entity)
      this.entity = new_location.entity;

    if(new_location.parent_id)
      this.parent_id = new_location.parent_id;

    if(this.entity)
      this.entity.location = this;
  };

  this.within_distance = function(x, y, z, distance){
    return Math.sqrt(Math.pow(this.x - x, 2) + Math.pow(this.y - y, 2) + Math.pow(this.z - z, 2)) < distance;
  };

  this.within_screen_coords = function(x, y, distance){
    var ax = ui.adjusted_x(this.cx, this.cy, this.cz);
    var ay = ui.adjusted_y(this.cx, this.cy, this.cz);
    return Math.sqrt(Math.pow(ax - x, 2) + Math.pow(ay - y, 2)) < distance;
  }

  this.check_clicked = function(x, y){
    return this.within_screen_coords(x, y, this.entity.size);
  }

  this.to_s = function() { return (Math.round(this.x*100)/100) + "," +
                                  (Math.round(this.y*100)/100) + "," +
                                  (Math.round(this.z*100)/100); }

  this.toJSON = function(){ return new JRObject("Motel::Location", this, 
                                                ["toJSON", "entity", "movement_strategy"]).toJSON(); };
  //JRObject.class_registry['Motel::Location'] = Location;
};
