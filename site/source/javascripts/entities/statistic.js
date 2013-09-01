/* Omega Javascript Stat
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega StatResult
 */
function Statistic(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Stats::StatResult'
}

/* Return specified stat
 */
Statistic.with_id = function(id, args, cb){
  Entities().node().web_request('stats::get', id, args,
                                function(res){
    if(res.result){
      var stat = new Statistic(res.result);
      cb.apply(null, [stat]);
    }
  });
}
