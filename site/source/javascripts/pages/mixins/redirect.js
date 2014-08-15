/* Omega Page Redirect Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.Redirect = {
  /// XXX needed to stub out get/set window location in test suite
  url : function(){
    return window.location;
  },

  redirect_to : function(value){
    window.location = value;
  }
};
