/* Omega JS Account Page Session Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.AccountSession = {
  _valid_session : function(){
    var _this = this;
    var user  = this.session.user;
    this.details.set(user);

    /// load entities owned by user
    Omega.Ship.owned_by(user.id, this.node,
      function(ships) { _this.process_entities(ships); });
    Omega.Station.owned_by(user.id, this.node,
      function(stations) { _this.process_entities(stations); });

    /// load user stats
    /// TODO configurable stats
    Omega.Stat.get('users_with_most', ['entities', 10], this.node,
      function(stat_result) { _this.process_stat(stat_result); });
  },

  _invalid_session : function(){}
};
