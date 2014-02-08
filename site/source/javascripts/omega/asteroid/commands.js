/* Omega Asteroid Command Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.AsteroidCommands = {
  has_details : true,

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

  _resources_retrieved : function(response, cb){
    var resource_details = '';

    if(response.error){
      resource_details =
        'Could not load resources: ' + response.error.message;
    }else{
      var result = response.result;
      for(var r = 0; r < result.length; r++){
        var resource = result[r];
        var id   = 'Resource: ' + resource.id;
        var text = resource.quantity + ' of ' + resource.material_id;
        resource_details += id   + '<br/>' +
                            text + '<br/>';
      }
    }

    cb(resource_details);
  }
};
