/* Omega Asteroid Command Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.AsteroidCommands = {
  retrieve_details : function(page, details_cb){
    var title   = 'Asteroid: ' + this.name;
    var loc     = '@ ' + this.location.to_s();
    var details = title + '<br/>' +
                  loc   + '<br/>';
    details_cb(details);

    var _this = this;
    page.node.http_invoke('cosmos::get_resources', this.id,
      function(response){
        _this._resources_retrieved(response, details_cb);
      });
  },
};
