/* Omega JS Canvas UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/dialog"
//= require "ui/canvas/controls"
//= require "ui/canvas/entity_container"
//= require "ui/canvas/skybox"
//= require "ui/canvas/axis"
//= require "ui/canvas/star_dust"

//= require "ui/canvas_mixins/mouse"
//= require "ui/canvas_mixins/scene"
//= require "ui/canvas_mixins/entities"
//= require "ui/canvas_mixins/cam"

// TODO remove these two from here (?)
//= require 'ui/canvas/lamp'
//= require 'ui/canvas/progress_bar'

Omega.UI.Canvas = function(parameters){
  this.controls         = new Omega.UI.CanvasControls({canvas: this});
  this.dialog           = new Omega.UI.CanvasDialog({canvas: this});
  this.entity_container = new Omega.UI.CanvasEntityContainer({canvas : this});
  this.skybox           = new Omega.UI.CanvasSkybox({});
  this.axis             = new Omega.UI.CanvasAxis();
  this.star_dust        = new Omega.UI.CanvasStarDust();
  this.canvas           = $('#omega_canvas');
  this.root             = null;
  this.entities         = [];

  /// need handle to page the canvas is on to
  /// - lookup missions
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.Canvas.prototype = {
  /// Wire up canvas DOM component
  wire_up : function(){
    this.wire_up_mouse();
    this.controls.wire_up();
    this.entity_container.wire_up();
  }
};

/// Event callback which may be registered to trigger animation
Omega.UI.Canvas.trigger_animation = function(canvas){
  canvas.animate();
};

THREE.EventDispatcher.prototype.apply( Omega.UI.Canvas.prototype );

$.extend(Omega.UI.Canvas.prototype, Omega.UI.CanvasMouseHandler);
$.extend(Omega.UI.Canvas.prototype, Omega.UI.CanvasSceneManager);
$.extend(Omega.UI.Canvas.prototype, Omega.UI.CanvasEntitiesManager);
$.extend(Omega.UI.Canvas.prototype, Omega.UI.CanvasCameraManager);
