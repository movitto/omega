/* Omega Solar System Title Text
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/subzer0_regular.typeface"

Omega.Scenes.IntroTitle = function(text){
  this.init_gfx(text);
};

Omega.Scenes.IntroTitle.prototype = {
  text_opts : {
    height        : 12,
    width         : 7,
    curveSegments : 2,
    font          : 'subzer0',
    size          : 48
  },

  _material : function(){
    return new THREE.MeshBasicMaterial({ color: 0x3366FF, overdraw: true  });
  },

  _geometry : function(text){
    var geo = new THREE.TextGeometry(text, this.text_opts);
    THREE.GeometryUtils.center(geo);
    return geo;
  },

  init_gfx : function(text){
    /// return if already initialized
    if(this.components) return;

    var material = this._material();
    var geometry = this._geometry(text);
    this.text    = new THREE.Mesh(geometry, material);
    this.text.position.set(0,0,0);

    this.components = [this.text];
    this.shader_components = [];
  },

  run_effects : function(){}
};

THREE.EventDispatcher.prototype.apply( Omega.Scenes.IntroTitle.prototype );
