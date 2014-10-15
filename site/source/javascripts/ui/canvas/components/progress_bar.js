/* Omega JS Canvas ProgressBar Scene Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// Make sure to specify
///   - id of component
///   - width: line width
///   - length : total line length
///   - axis : world axis on which to render progression
///   - color1 : first color of progression
///   - color2 : contrasting color for progression
///   - vertices : inital position of progression component vertices
//
/// TODO add optional parameterized border around entire progress bar
Omega.UI.CanvasProgressBar = function(parameters){
  this.components = [];
  $.extend(this, parameters);
};

Omega.UI.CanvasProgressBar.prototype = {
  init_gfx : function(){
    if(this.components.length > 0) return;

    var mat1 = new THREE.LineBasicMaterial({color     : this.color1,
                                            linewidth : this.width});
    var mat2 = new THREE.LineBasicMaterial({color     : this.color2,
                                            linewidth : this.width});

    var geo1 = new THREE.Geometry();
    var geo2 = new THREE.Geometry();

    var g1v0 = new THREE.Vector3(this.vertices[0][0][0],
                                 this.vertices[0][0][1],
                                 this.vertices[0][0][2]);
    var g1v1 = new THREE.Vector3(this.vertices[0][1][0],
                                 this.vertices[0][1][1],
                                 this.vertices[0][1][2]);
    var g2v0 = new THREE.Vector3(this.vertices[1][0][0],
                                 this.vertices[1][0][1],
                                 this.vertices[1][0][2]);
    var g2v1 = new THREE.Vector3(this.vertices[1][1][0],
                                 this.vertices[1][1][1],
                                 this.vertices[1][1][2]);
    geo1.vertices.push(g1v0);
    geo1.vertices.push(g1v1);
    geo2.vertices.push(g2v0);
    geo2.vertices.push(g2v1);

    this.component1  = new THREE.Line(geo1, mat1);
    this.component2  = new THREE.Line(geo2, mat2);
    this.components = [this.component1, this.component2];

    this.component1.omega_obj = this.component2.omega_obj = this;
  },

  update : function(percentage){
    var comp1len = percentage * this.length;
    var comp2len = this.length - comp1len;
    var border = percentage < 0.5 ?
                 (comp2len - this.length / 2) :
                 (this.length / 2 - comp1len);
    this.component1.geometry.vertices[1][this.axis] = border;
    this.component2.geometry.vertices[0][this.axis] = border;
    this.component1.geometry.verticesNeedUpdate = true;
    this.component2.geometry.verticesNeedUpdate = true;
  },

  clone : function(){
    return new Omega.UI.CanvasProgressBar({width      : this.width,
                                           length     : this.length,
                                           axis       : this.axis,
                                           color1     : this.color1,
                                           color2     : this.color2,
                                           components : this.components,
                                           component1 : this.component1,
                                           component2 : this.component2,
                                           vertices   : this.vertices});
  },

  /// canvas scene 'rendered_in' callback
  rendered_in : function(canvas, component){
    component.lookAt(canvas.cam.position);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasProgressBar.prototype );
