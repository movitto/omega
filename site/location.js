function Location(){
  this.id = null;
  this.x = 0;
  this.y = 0;
  this.z = 0;
  this.movement_strategy = null;
  this.entity = null;
  this.draw   = ui.draw_nothing;

  this.update = function(new_location){
    this.id = new_location.id;
    this.x = new_location.x;
    this.y = new_location.y;
    this.z = new_location.z;

    if(new_location.movement_strategy)
      this.movement_strategy = new_location.movement_strategy;

    if(new_location.entity)
      this.entity = new_location.entity;

    if(this.entity)
      this.entity.location = this;
  };

  this.within_distance = function(x, y, distance){
    return Math.sqrt(Math.pow(this.x - x, 2) + Math.pow(this.y - y, 2)) < distance;
  };

  this.toJSON = function(){ return new JRObject("Motel::Location", this).toJSON(); };
  //JRObject.class_registry['Motel::Location'] = Location;
};
