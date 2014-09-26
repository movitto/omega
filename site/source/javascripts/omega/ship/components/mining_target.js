/* Omega JS Ship Mining Target Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMiningTarget = {
  _init_mining_cb : function(){
    var _this = this;
    if(!this._mining_component_moved)
      this._mining_component_moved = function(){
        _this.mining_vector.update();
      };
  },

  is_mining : function(){
    return !!(this.mining) && !!(this.mining_asteroid);
  },

  set_mining : function(resource, entity){
    this.mining = resource;
    this.mining_asteroid = entity;
    this._init_mining_cb();
    this.mining_vector.update();

    if(!this.hasEventListener('movement', this._mining_component_moved))
      this.addEventListener('movement',   this._mining_component_moved);
  },

  clear_mining : function(){
    if(!this.mining) return;
    this._init_mining_cb();

    this.removeEventListener('movement', this._mining_component_moved);
    this.mining = null;
    this.mining_asteroid = null;
  }
};
