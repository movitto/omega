/* Omega Stats Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "pages/mixins/base"

//= require "pages/stats/init"
//= require "pages/stats/login"
//= require "pages/stats/runner"

Omega.Pages.Stats = function(){
  this.init_page();
  this.init_stats();
}

$.extend(Omega.Pages.Stats.prototype, Omega.Pages.Base);

$.extend(Omega.Pages.Stats.prototype, Omega.Pages.StatsInitializer);
$.extend(Omega.Pages.Stats.prototype, Omega.Pages.StatsSession);
$.extend(Omega.Pages.Stats.prototype, Omega.Pages.StatsRunner);

$(document).ready(function(){
  if(Omega.Test) return;

  var stats = new Omega.Pages.Stats();
  stats.login(function(){
    stats.start();
  });
});
