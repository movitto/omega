/* Omega JS Canvas Axis Scene Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasAxis = function(parameters){
  this.size = 100000;
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.UI.CanvasAxis.prototype = {
  id : 'canvas_axis',

  load_gfx : function(){
    if(typeof(Omega.UI.CanvasAxis.gfx) !== 'undefined') return;
    Omega.UI.CanvasAxis.gfx = {
      xy : this._new_axis(this._new_v(-this.size, 0, 0), this._new_v(this.size, 0, 0), 0xFF0000), /// red
      yz : this._new_axis(this._new_v(0, -this.size, 0), this._new_v(0, this.size, 0), 0x00FF00), /// green
      xz : this._new_axis(this._new_v(0, 0, -this.size), this._new_v(0, 0, this.size), 0x0000FF), /// blue
      distances1 : this._new_marker(20000, 40),
      distances2 : this._new_marker(15000, 40),
      distances3 : this._new_marker(10000, 40),
      distances4 : this._new_marker(5000, 40),
      distances5 : this._new_marker(3000, 40),
      distances6 : this._new_marker(2000, 20),
      distances7 : this._new_marker(1000, 20)
    };
  },

  init_gfx : function(){
    if(this.components.length > 0) return;
    this.load_gfx();

    /// just reference it, assuming we're only going to need the one axis
    for(var a in Omega.UI.CanvasAxis.gfx)
      this.components.push(Omega.UI.CanvasAxis.gfx[a]);
  },

  _new_v : function(x,y,z){
    return new THREE.Vector3(x,y,z);
  },

  _new_axis : function(p1, p2, color){
    var geo = new THREE.Geometry();
    var mat = new THREE.LineBasicMaterial({color: color, lineWidth: 1});
    geo.vertices.push(p1, p2);
    return new THREE.Line(geo, mat);
  },

  _new_marker : function(distance, segments){
    var mat = new THREE.MeshBasicMaterial({color: 0xcccccc });
    var geo = new THREE.TorusGeometry(distance, 5, segments, segments);
    var mesh = new THREE.Mesh(geo, mat);
    mesh.rotation.x = 1.57;
    return mesh;
  },

  scene_components : function(){
    return this.components;
  },

  has_effects : function(){ return false; },
  scale_position : function(){}
};

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasAxis.prototype );
