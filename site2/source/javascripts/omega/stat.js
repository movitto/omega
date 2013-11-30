/* Omega Stat JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega StatResult
 */
Omega.Stat = function(parameters){
  $.extend(this, parameters);
}

Omega.Stat.prototype = {
  json_class : 'Stats::StatResult'
}

Omega.Stat.get = function(id, args, node, cb){
  node.http_invoke('stats::get', id, args,
    function(response){
      var stats = [];
      if(response.result)
        for(var s = 0; s < response.result.length; s++)
          stats.push(new Omega.Stat(response.result[s]));
      cb(stats);
    });
};
