/* Omega Ship Indicator Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipIndicator = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_gfx(event_cb);
};

Omega.ShipIndicator.prototype = {
  clone : function(){
    return new Omega.ShipIndicator();
  },

  material : function(event_cb){
    var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                       Omega.Config.resources.indicator.material;
    var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
    texture.omega_id = 'ship.indicator';

    return new THREE.SpriteMaterial({ map: texture,
                                      useScreenCoordinates: false,
                                      transparent : true,
                                      depthWrite : false,
                                      color : 0x0000FF});
  },

  init_gfx : function(event_cb){
    this.sprite = new THREE.Sprite(this.material(event_cb));
    this.sprite.scale.set(400, 400, 400);
    this.sprite.omega_obj = this;
  }
};
