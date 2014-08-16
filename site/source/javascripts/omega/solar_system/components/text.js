/* Omega Solar System Text
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/reality_hyper_regular.typeface"

Omega.SolarSystemTextMaterial = function(){
  this.material = this._material();
};

Omega.SolarSystemTextMaterial.prototype = {
  _material : function(){
    return new THREE.MeshBasicMaterial({ color: 0x3366FF, overdraw: true  });
  }
};

Omega.SolarSystemText = function(args){
  if(!args) args = {};
  var text = args['text'];
  var material = args['material'];

  this.text = this._text(text, material);
  this.text.omega_obj = this;
};

Omega.SolarSystemText.prototype = {
  text_opts : {
    height        : 12,
    width         : 5,
    curveSegments : 2,
    font          : 'reality hyper',
    size          : 48
  },

  _geometry : function(text){
    var geo = new THREE.TextGeometry(text, this.text_opts);
    THREE.GeometryUtils.center(geo);
    return geo;
  },

  _text : function(text, material){
    return new THREE.Mesh(this._geometry(text), material);
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;
    this.text.position.set(loc.x, loc.y + 50, loc.z);
  },

  rendered_in : function(canvas, component){
    component.lookAt(canvas.cam.position);
  }
};
