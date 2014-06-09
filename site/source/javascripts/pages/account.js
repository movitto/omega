/* Omega Account Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/session_validator"

//= require "ui/pages/account_details"
//= require "ui/pages/account_dialog"

//= require "ui/splash"

/// TODO account option where user can setup
///      uri's to stream background audio from

/// TODO framerate config on accounts page (slider)

Omega.Pages.Account = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.dialog  = new Omega.UI.AccountDialog();
  this.details = new Omega.UI.AccountDetails({page : this});
};

Omega.Pages.Account.prototype = {
  wire_up : function(){
    this.details.wire_up();

    $('#account_info_clear_notices').on('click', function(){
      new Omega.UI.SplashScreen().clear_notices();
    });
  },

  start : function(){
    var _this = this;
    this.validate_session(
      function(){ _this._valid_session(); }, /// validated
      function(){}                           /// invalid - TODO redirect to index?
    );
  },

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

$.extend(Omega.Pages.Account.prototype, Omega.UI.SessionValidator);

$(document).ready(function(){
  if(Omega.Test) return;

  var account = new Omega.Pages.Account();
  account.wire_up();
  account.start();
});
