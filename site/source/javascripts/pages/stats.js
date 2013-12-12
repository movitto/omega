/* Omega Stats Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.Stats = function(){
  this.stat_results = {};

  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
}

Omega.Pages.Stats.prototype = {
  interval : 3000,

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
      }, Omega.Pages.Stats.prototype.interval, true);
  },

  retrieve_stats : function(){
    var _this = this;
    for(var s = 0; s < this.config.stats.length; s++){
      var stat      = this.config.stats[s];
      var stat_id   = stat[0];
      var stat_args = stat[1];
      Omega.Stat.get(stat_id, stat_args, this.node,
        function(stat_result){
          if(stat_result){
            _this.update_stats(stat_result);
            _this.refresh_stats();
          }
        });
    }
  },

  update_stats : function(stat_result){
    var stat = stat_result.stat;
    this.stat_results[stat.stat_id] = stat_result;
  },

  refresh_stats : function(){
    var container = $('#stats ul');
    container.html('');
    for(var s in this.stat_results){
      var stat_result = this.stat_results[s];
      var stat = stat_result.stat;
      var stat_txt = stat.description + ": " + stat_result.value;
      var stat_li  = $("<li/>", {text : stat_txt});
      container.append(stat_li);
    }
  }
}

$(document).ready(function(){
  var stats = new Omega.Pages.Stats();
  stats.login(function(){
    stats.start();
  });
});
