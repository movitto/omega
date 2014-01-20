/* Omega Station Command Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationCommands = {
  retrieve_details : function(page, details_cb){
    /// TODO also construction percentage
    var title = 'Station: ' + this.id;
    var loc   = '@ ' + this.location.to_s();

    var resources = ['Resources:'];
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.push(resource.quantity + ' of ' + resource.material_id);
    }

    var _this = this;
    var construct_cmd = $('<span/>',
      {id    : 'station_construct_' + this.id,
       class : 'station_construct details_command',
       text  : 'construct'})
     construct_cmd.data('station', this);
     construct_cmd.click(function(){ _this._construct(page); });

    var details = [title, loc].concat(resources);
    for(var d = 0; d < details.length; d++) details[d] += '<br/>';
    if(page.session && this.belongs_to_user(page.session.user_id))
      details.push(construct_cmd);
    details_cb(details);
  }
};
