/* Omega Ship Attack Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipAttackInteractions = {
  /// Return list of valid attack targets n vicinity
  _attack_targets : function(page){
    var _this = this;
    return $.grep(page.all_entities(), function(e){
             return  e.json_class == 'Manufactured::Ship'    &&
                    !e.belongs_to_user(page.session.user_id) &&
                     e.location.is_within(_this.attack_distance,
                                          _this.location)    &&
                     e.alive()
           });
  },

  /// Launch dialog to select ship attack target
  _select_attack_target : function(page){
    var _this = this;
    var targets = this._attack_targets(page);
    this.dialog().show_attack_dialog(page, this, targets);
  },

  /// Invoke ship attack command
  _start_attacking : function(page, evnt){
    var _this  = this;
    var target = $(evnt.currentTarget).data('target');
    page.node.http_invoke('manufactured::attack_entity', this.id, target.id,
      function(response){
        if(response.error)
          _this._attack_failed(response);
        else
          _this._attack_success(response, page, target);
      });
  },

  /// Interal callback invoked on attack failure
  _attack_failed : function(response){
    this.dialog().title = 'Attack Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  /// Internal callback invoked on successful attack
  _attack_success : function(response, page, target){
    var _this = this;
    this.dialog().hide();
    this.attacking = target;
    page.canvas.reload(_this, function(){
      _this.update_gfx();
    });
  }
};
