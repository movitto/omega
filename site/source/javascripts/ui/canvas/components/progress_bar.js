/* Omega JS Canvas ProgressBar Scene Component
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasProgressBar = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.color1 = args['color1'];
  this.color2 = args['color2'];
  this.size   = args['size'];

  if(args['sprite1'] && args['sprite2']){
    this.sprite1 = args['sprite1'];
    this.sprite2 = args['sprite2'];

  }else{
    this.init_gfx(event_cb);
  }

  this.components = [this.sprite1, this.sprite2];
};

Omega.UI.CanvasProgressBar.prototype = {
  clone : function(){
    return new Omega.UI.CanvasProgressBar({sprite1 : this.sprite1.clone(),
                                           sprite2 : this.sprite2.clone(),
                                           size    : this.size});
  },

  _texture : function(event_cb){
    var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                       Omega.Config.resources.progress_bar.material;
    return THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  },

  _material : function(color, event_cb){
    return new THREE.SpriteMaterial({ map: this._texture(event_cb),
                                      useScreenCoordinates: false,
                                      color : color,
                                      alignment: THREE.SpriteAlignment.topLeft});
  },

  init_gfx : function(event_cb){
    this.sprite1 = new THREE.Sprite(this._material(this.color1, event_cb));
    this.sprite2 = new THREE.Sprite(this._material(this.color2)); /// event_cb not needed since same texture used

    this.sprite1.scale.set(this.size[0], this.size[1], 1);
    this.sprite2.scale.set(this.size[0], this.size[1], 1);
  },

  update : function(percentage){
    this.sprite1.scale.set(this.size[0] * percentage, this.size[1], 1);
  }
};
