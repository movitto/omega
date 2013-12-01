/* Omega Stats Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.Stats = function(){
  this.stats = {};

  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
}

Omega.Pages.Stats.prototype = {
  interval : 5000,

  login : function(cb){
    /// XXX disable session cookies globally
    Omega.Session.cookies_enabled = false;

    /// login anon user
    var anon = new Omega.User({id       : this.config.anon_user,
                               password : this.config.anon_pass});
    Omega.Session.login(anon, this.node, cb);
  },

  start : function(){
    var _this = this;
    this.stats_timer =
      $.timer(function(){
        _this.retrieve_stats();
      }, Omega.Pages.Stats.prototype.interval);
  },

  retrieve_stats : function(){
    var _this = this;
    for(var s = 0; s < this.config.stats.length; s++){
      var stat      = this.config.stats[s];
      var stat_id   = stat[0];
      var stat_args = stat[1];
      Omega.Stat.get(stat_id, stat_args, this.node,
        function(stats){
          _this.update_stats(stats);
          _this.refresh_stats();
        });
    }
  },

  update_stats : function(stats){
    for(var s = 0; s < stats.length; s++){
      var stat = stats[s];
      this.stats[stat.stat_id] = stat;
    }
  },

  refresh_stats : function(){
    var container = $('#stats ul');
    container.html('');
    for(var s in this.stats){
      var stat = this.stats[s];
      var stat_txt = stat.description + ": " + stat.value;
      var stat_li  = $("<li/>", {text : stat_txt});
      container.append(stat_li);
    }
  }
}

$(document).ready(function(){
//  var stats = new Omega.Pages.Stats();
//  stats.login(function(){
//    stats.start();
//  });
});
