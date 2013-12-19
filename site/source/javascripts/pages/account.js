/* Omega Account Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/pages/account_details"
//= require "ui/pages/account_dialog"

Omega.Pages.Account = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.dialog  = new Omega.UI.AccountDialog();
  this.details = new Omega.UI.AccountDetails({page : this});

  var _this = this;
  this.session = Omega.Session.restore_from_cookie();
  if(this.session != null){
    this.session.validate(this.node, function(response){
      if(response.error){
        _this.session = null;
        /// TODO redirect to index?
      }else{
        var user = response.result;
        _this.details.username(user.id);
        _this.details.email(user.email);
        _this.details.gravatar(user.email);

        /// load entities owned by user
        Omega.Ship.owned_by(_this.session.user_id, _this.node,
          function(ships) { _this.process_entities(ships); });
        Omega.Station.owned_by(_this.session.user_id, _this.node,
          function(stations) { _this.process_entities(stations); });

        /// load user stats
        /// TODO configurable stats
        Omega.Stat.get('with_most', ['entities', 10], _this.node,
          function(stat_result) { _this.process_stat(stat_result); });
      }
    });
  }
};

Omega.Pages.Account.prototype = {
  wire_up : function(){
    this.details.wire_up();
  },

  process_entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  process_entity : function(entity){
    this.details.entity(entity);
  },

  process_stat : function(stat_result){
    if(stat_result == null) return;
    var stat = stat_result.stat;
    for(var v = 0; v < stat_result.value.length; v++){
      var value = stat_result.value[v];
      if(value == this.session.user_id){
        this.details.add_badge(stat.id, stat.description, v)
        break;
      }
    }
  }
};

$(document).ready(function(){
  if(Omega.Test) return;

  var account = new Omega.Pages.Account();
  account.wire_up();
});
