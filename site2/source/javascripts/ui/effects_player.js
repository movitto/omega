/* Omega JS Effects Player UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.EffectsPlayer = function(parameters){
  /// need handle to page to
  /// - get canvas scene entities
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.EffectsPlayer.prototype = {
  interval : 150,

  wire_up : function(){
    var _this = this;
    $(document).on('visibilitychange', function(evnt){
      if(_this.effects_timer){
        if(document.hidden)
          _this.effects_timer.stop();
        else if(_this.playing)
          _this.effects_timer.play();
      }
    });
  },

  start : function(){
    this._create_timer();
    this.effects_timer.play();
    this.playing = true;
  },

  _create_timer : function(){
    if(this.effects_timer) return;

    var _this = this;
    this.effects_timer =
      $.timer(function(){
        _this._run_effects();
      }, Omega.UI.EffectsPlayer.prototype.interval, false);
  },

  _run_effects : function(){
    var objects = this.page.canvas.scene.getDescendants();
    for(var c = 0; c < objects.length; c++){
      var obj = objects[c];
      if(obj.omega_entity && obj.omega_entity.run_effects)
        obj.omega_entity.run_effects();
    }
    this.page.canvas.animate();
  }
};
