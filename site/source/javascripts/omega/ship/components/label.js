/* Omega Ship Label
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/components/label"

Omega.ShipLabel = function(args){
  if(!args) args = {};
  var text = args['text'];

  this.text = text;
  this.init_gfx();
};

Omega.ShipLabel.prototype = {
  font : 'Bold 28px Arial',
  fill : '#FFFFFF',

  init_gfx : function(){
    this._fill(this.text, 0, 30);
    this.sprite = this._sprite();
    this.sprite.position.set(300, 100, 0);
    this.sprite.scale.set(500, 250, 1.0);
    this.sprite.omega_obj = this;
  }
};

$.extend(Omega.ShipLabel.prototype, Omega.UI.CanvasLabel);
