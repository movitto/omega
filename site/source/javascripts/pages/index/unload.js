/* Omega JS Index Page Unloader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.IndexUnloader = {
  /// cleanup index page operations
  unload : function(){
    this.unloading = true;
    this.node.close();
  }
};
