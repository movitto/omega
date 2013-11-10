/* Omega Station JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Station = function(parameters){
  $.extend(this, parameters);
};

Omega.Station.prototype = {
  json_class : 'Manufactured::Station'
};

// Return stations owned by the specified user
Omega.Station.owned_by = function(user_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Station', 'owned_by', user_id,
    function(response){
      var stations = [];
      if(response.result)
        for(var e = 0; e < response.result.length; e++)
          stations.push(new Omega.Station(response.result[e]));
      cb(stations);
    });
}
