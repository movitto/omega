/* Omega JS Effects Player UI Component
 *
 * Implements the traditional 'game loop' for the Omega JS UI
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
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

  /// Number of entities we process per cycle can be limited
  /// by setting 'entities_per_cycle' below.
  /// If null, all entities will be processed
  if(this.entities_per_cycle)
    this._run_entity_effects = this._run_partial_entity_effects;
  else
    this._run_entity_effects = this._run_all_entity_effects;

  /// By default we enforce a constant frame rate
  this._run_effects = this._run_strict_effects;

  /// Replace above with the following to
  /// disable constant frame rate enforcement
  //this._run_effects = this._run_lax_effects;
};

Omega.UI.EffectsPlayer.prototype = {
  /// Frame interval in ms:
  ///   50 = 20fps
  ///   20 = 50fps
  ///   10 = 100fps
  interval  : 50,
  max_skips :  5,

  /// Set to null to update all entities on every cycle
  entities_per_cycle : 30,

  /// Internal (stubbable) helper returning document.hidden
  _document_hidden : function(){
    return document.hidden;
  },

  /// Wire up effects player to page DOM
  ///
  /// Toggle effects loop on page visibilty changes
  wire_up : function(){
    /// pause effects player when document is hidden
    var _this = this;
    $(document).on('visibilitychange', function(evnt){
      if(_this.effects_timer){
        if(_this._document_hidden())
          _this.effects_timer.stop();
        else if(_this.playing)
          _this.effects_timer.play();
      }
    });
  },

  /// Add entity to effects player
  add : function(entity){
    this.entities.push(entity);
  },

  /// Remove entity specified by id from effects player
  remove : function(entity_id){
    var entity = $.grep(this.entities, function(e){
      return e.id == entity_id;
    })[0];
    this.entities.splice(this.entities.indexOf(entity), 1);
  },

  /// Clear all entities from effects player
  clear : function(){
    this.entities = [];
  },

  /// Return bool indicating if effects player has specified entity
  has : function(entity_id){
    return $.grep(this.entities, function(e){ return e.id == entity_id }).length > 0;
  },

  /// Start running the effects player / game loop
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
