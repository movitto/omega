/* Omega Planet Label
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/components/label"

Omega.PlanetLabel = function(args){
  if(!args) args = {};
  var text = args['text'];

  this.text = text;
  this.init_gfx();
};

Omega.PlanetLabel.prototype = {
  font : 'Bold 128px Arial',
  fill : '#FFFFFF',

  init_gfx : function(){
    this._fill(this.text, 0, 130);
    this.sprite = this._sprite();
    this.sprite.position.set(5000, 5000, 0);
    this.sprite.scale.set(1000, 500, 1.0);
    this.sprite.omega_obj = this;
  }
};

$.extend(Omega.PlanetLabel.prototype, Omega.UI.CanvasLabel);
