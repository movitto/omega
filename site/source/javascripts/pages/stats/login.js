/* Omega JS Index Page Session Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.StatsSession = {
  login : function(cb){
    /// XXX disable session cookies globally
    Omega.Session.cookies_enabled = false;

    /// login anon user
    var anon = new Omega.User({id       : Omega.Config.anon_user,
                               password : Omega.Config.anon_pass});
    Omega.Session.login(anon, this.node, cb);
  }
};
