/* Omega JS Ship Attack Target Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipAttackTarget = {
  _init_attacking_cb : function(){
    var _this = this;
    if(!this._attack_component_moved)
      this._attack_component_moved = function(){
        _this.attack_vector.update();
        _this.attack_component().update();
      };
  },

  set_attacking : function(tgt){
    this.attacking = tgt;
    this._init_attacking_cb();

    if(!this.hasEventListener('movement', this._attack_component_moved))
      this.addEventListener('movement',   this._attack_component_moved);
    if(!tgt.hasEventListener('movement',  this._attack_component_moved))
      tgt.addEventListener('movement',    this._attack_component_moved);
  },

  clear_attacking : function(){
    if(!this.attacking) return;
    this._init_attacking_cb();

    this.removeEventListener('movement', this._attack_component_moved);
    this.attacking.removeEventListener('movement', this._attack_component_moved);
    this.attacking = null;
  }
};
