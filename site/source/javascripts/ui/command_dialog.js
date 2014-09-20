/* Omega JS Command Dialog
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/dialog"

//= require_tree './dialogs'

Omega.UI.CommandDialog = function(parameters){
  $.extend(this, parameters);
};

Omega.UI.CommandDialog.prototype = {};

/// Provide singleton instance (leveraged in entities
Omega.UI.CommandDialog.instance = function(){
  if(!Omega.UI.CommandDialog._instance)
    Omega.UI.CommandDialog._instance = new Omega.UI.CommandDialog();
  return Omega.UI.CommandDialog._instance;
};

$.extend(Omega.UI.CommandDialog.prototype, new Omega.UI.Dialog());
$.extend(Omega.UI.CommandDialog.prototype,     Omega.UI.ErrorDialog);
$.extend(Omega.UI.CommandDialog.prototype,     Omega.UI.MovementDialog);
$.extend(Omega.UI.CommandDialog.prototype,     Omega.UI.AttackDialog);
$.extend(Omega.UI.CommandDialog.prototype,     Omega.UI.DockingDialog);
$.extend(Omega.UI.CommandDialog.prototype,     Omega.UI.MiningDialog);
$.extend(Omega.UI.CommandDialog.prototype,     Omega.UI.ConstructionDialog);
