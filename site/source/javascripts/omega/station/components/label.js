/* Omega Station Label
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/components/label"

Omega.StationLabel = function(args){
  if(!args) args = {};
  var text = args['text'];

  this.text = text;
  this.init_gfx();
};

Omega.StationLabel.prototype = {
  font : 'Bold 64px Arial',
  fill : '#FFFFFF',

  init_gfx : function(){
    this._fill(this.text, 0, 70);
    this.sprite = this._sprite();
    this.sprite.position.set(750, 1500, 0);
    this.sprite.scale.set(500, 250, 1.0);
    this.sprite.omega_obj = this;
  }
};

$.extend(Omega.StationLabel.prototype, Omega.UI.CanvasLabel);
