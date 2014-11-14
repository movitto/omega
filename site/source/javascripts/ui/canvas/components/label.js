/* Omega Canvas Label
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasLabel = {
  width: 500,

  _canvas : function(){
    this.__canvas = this.__canvas || document.createElement("canvas");
    return this.__canvas;
  },

  _context : function(){
    return this._canvas().getContext("2d");
  },

  _fill : function(text, x, y){
    var canvas  = this._canvas();
    var context = this._context();


    /// subclass should define
    canvas.width      = this.width;
    context.font      = this.font;
    context.fillStyle = this.fill;

    context.fillText(text, x, y);
  },

  _texture : function(){
    if(!this.__texture){
      this.__texture = new THREE.Texture(this._canvas());
      this.__texture.needsUpdate = true;
    }
    return this.__texture;
  },

  _material : function(){
    this.__material = this.__material ||
                      new THREE.SpriteMaterial({ map : this._texture(),
                                                 useScreenCoordinates: false,
                                                 alignment: THREE.SpriteAlignment.topLeft});
    return this.__material;
  },

  _sprite : function(){
    return new THREE.Sprite(this._material());
  }
};
