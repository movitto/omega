/* Omega JS Canvas Updatable Particles Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.UpdatableParticles = function(){};

/// Subclasses should implement:
/// - _update_emitters : updating the emitters as necessary when updates are enabled
/// - enabled_state    : returning bool indicating if pariticle component is in enabled state
Omega.UI.UpdatableParticles.prototype = {
  disable_updates : function(){
    this.update = this._disabled_update;
  },

  enable_updates : function(){
    this.update = this._enabled_update;
  },

  _disabled_update : function(){},

  _enabled_update : function(){
    this._update_emitters();
  },

  update_state : function(){
    if(this.enabled_state()){
      this.enable_updates();
      this.enable();

    }else{
      this.disable_updates();
      this.disable();
    }
  }
};

Omega.UI.UpdatableParticles.prototype.update =
  Omega.UI.UpdatableParticles.prototype._disabled_update;
