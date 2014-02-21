/* Omega JS Effects Player UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.EffectsPlayer = function(parameters){
  this.entities = [];
  this.skipped_interval = null;
  this.skipped = 0;
  this._effects_counter = 0;

  /// need handle to page to
  /// - get canvas scene entities
  this.page = null;

  $.extend(this, parameters);

  if(this.entities_per_cycle)
    this._run_entity_effects = this._run_partial_entity_effects;
  else
    this._run_entity_effects = this._run_all_entity_effects;

  this._run_effects = this._run_strict_effects;

  /// replace above with the following to
  /// disable constant frame rate enforcement
  //this._run_effects = this._run_strict_effects;
};

Omega.UI.EffectsPlayer.prototype = {
  interval  : 10, /// frame interval in ms, = 50fps
  max_skips :  5,

  /// set to null to update all entities on every cycle
  entities_per_cycle : 20,

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
      }, this.interval, false);
  },

  _run_all_entity_effects : function(){
    for(var e = 0; e < this.entities.length; e++)
      this.entities[e].run_effects(this.page);
  },

  _run_partial_entity_effects : function(){
    if(this._effects_counter >= this.entities.length) this._effects_counter = 0;

    var stop = this._effects_counter + this.entities_per_cycle;
    if(stop > this.entities.length) stop = this.entities.length;

    for(var e = this._effects_counter; e < stop; e++)
      this.entities[e].run_effects(this.page);

    this._effects_counter = stop;
  },

  _run_lax_effects : function(){
    this._run_entity_effects();
    this.page.canvas.animate();
  },

  _run_strict_effects : function(){
    var pre_effects = new Date();

    this._run_entity_effects();
    if(!this.skip_interval) this.page.canvas.animate();

    var post_effects   = new Date();
    var diff           = post_effects - pre_effects;
    var skip_time      = this.interval - diff;

    if(skip_time < 0 && !this.skip_interval){
      this.skip_interval = skip_time;
      this.skipped       = 1;

    }else if(this.skip_interval < 0 && this.skipped < this.max_skips){
      this.skip_interval += this.interval;
      this.skipped       += 1;

    }else{
      this.skip_interval = null;
      this.skipped       =    0;
    }
  }
};
