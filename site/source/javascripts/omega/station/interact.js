/* Omega Station Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/command_dialog"

//= require_tree './interact'

Omega.StationInteraction = {
  dialog : function(){
    return Omega.UI.CommandDialog.instance();
  }
}

$.extend(Omega.StationInteraction, Omega.StationConstructionInteractions);
