/* Omega JS Effects Player UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.EffectsPlayer = function(parameters){
  this.entities = [];

  /// need handle to page to
  /// - get canvas scene entities
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.EffectsPlayer.prototype = {
  interval : 50,

  wire_up : function(){
    /// pause effects player when document is hidden
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

  add : function(entity){
    this.entities.push(entity);
  },

  remove : function(entity_id){
    var entity = $.grep(this.entities, function(e){
      return e.id == entity_id;
    })[0];
    this.entities.splice(this.entities.indexOf(entity), 1);
  },

  clear : function(){
    this.entities = [];
  },

  has : function(entity_id){
    return $.grep(this.entities, function(e){ return e.id == entity_id }).length > 0;
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
    for(var e = 0; e < this.entities.length; e++){
      var entity = this.entities[e];
      if(entity.run_effects) entity.run_effects(this.page);
    }
    this.page.canvas.animate();
  }
};
