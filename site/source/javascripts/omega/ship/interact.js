/* Omega Ship Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/command_dialog"

//= require_tree './interact'

Omega.ShipInteraction = {
  /// Launch ship context action to perform operation with ship depending on
  /// context provided by specified target entity
  context_action : function(entity, page){
    if(!page.session || !this.belongs_to_user(page.session.user_id)) return;

    if(this._should_move_to(entity)){
      var offset = page.config.movement_offset;
          offset = (Math.random() * (offset.max - offset.min)) + offset.min;
      this._move(page, entity.location.x + offset,
                       entity.location.y + offset,
                       entity.location.z + offset);

    }else if(this._should_follow(entity)){
      this._follow(page, entity.id);

    } /// TODO else if(should_mine, should_dock)
  },

  dialog : function(){
    return Omega.UI.CommandDialog.instance();
  }
}

$.extend(Omega.ShipInteraction, Omega.ShipMovementInteractions);
$.extend(Omega.ShipInteraction, Omega.ShipAttackInteractions);
$.extend(Omega.ShipInteraction, Omega.ShipDockingInteractions);
$.extend(Omega.ShipInteraction, Omega.ShipTransferInteractions);
$.extend(Omega.ShipInteraction, Omega.ShipMiningInteractions);
