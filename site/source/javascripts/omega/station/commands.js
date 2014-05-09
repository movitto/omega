/* Omega Station Command Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationCommands = {
  has_details : true,

  _title_details : function(){
    var title_text = 'Station: ' + this.id;
    var title = $('<div/>', {id : 'station_title', text : title_text});
    return title;
  },

  _loc_details : function(){
    var loc_text = '@ ' + this.location.to_s();
    var loc = $('<div/>', {id : 'station_loc', text : loc_text});
    return loc;
  },

  _resource_details : function(){
    var resources = $('<div/>', {id : 'station_resources', text : 'Resources:'});
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.append(' ' + resource.quantity + ' of ' + resource.material_id);
    }
    return resources;
  },

  _command_details : function(page){
    var _this = this;
    var construct_cmd = $('<span/>',
      {id    : 'station_construct_' + this.id,
       class : 'station_construct details_command',
       text  : 'construct'})
     construct_cmd.data('station', this);
     construct_cmd.click(function(){ _this._construct(page); });
     return [construct_cmd];
  },

  _command_details_wrapper : function(page){
    var cmds_container = $('<div/>', {id : 'station_cmds'});
    return cmds_container;
  },

  retrieve_details : function(page, details_cb){
    /// TODO also construction percentage
    var details = [this._title_details(),
                   this._loc_details()].
           concat([this._resource_details(),
                   this._command_details_wrapper()]);

    if(page.session && this.belongs_to_user(page.session.user_id))
      details[details.length-1].append(this._command_details(page));

    details_cb(details);
  },

  refresh_details : function(){
    $('#station_loc').html(this._loc_details().html());
    $('#station_resources').html(this._resource_details().html());
  },

  refresh_cmds : function(page){
    var station_cmds = $('#station_cmds');
    station_cmds.html('');
    station_cmds.append(this._command_details(page));
  }
};
