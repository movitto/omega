/* Omega Base Page Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.Base = {
  init_page : function(){
    var config = {http_host : Omega.Config.http_host,
                  http_path : Omega.Config.http_path,
                  ws_host   : Omega.Config.ws_host,
                  ws_port   : Omega.Config.ws_port}
    this.node = new Omega.Node(config);
  }
};
