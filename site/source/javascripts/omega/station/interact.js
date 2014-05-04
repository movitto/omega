/* Omega Station Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/command_dialog"

Omega.StationInteraction = {
  dialog : function(){
    return Omega.UI.CommandDialog.instance();
  },

  /// TODO parameterize entity type/init!
  /// TODO generate random location in vicity of station and/or allow user
  /// to set a generation point around which new entities appear (within
  /// construction distance of station of course)
  _construct_properties : function(){
    return ['entity_type', 'Ship', 'type', 'mining', 'id', RJR.guid()];
  },

  _construct : function(page){
    var _this = this;

    var construct_args =
      ['manufactured::construct_entity', this.id].
        concat(this._construct_properties());

    var cb = function(response){
               if(response.error)
                 _this._construct_failed(response);
               else
                 _this._construct_success(response, page);
             };
    construct_args.push(cb)

    page.node.http_invoke.apply(page.node, construct_args);
  },

  _construct_failed : function(response){
    this.dialog().title = 'Construction Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  _construct_success : function(response, page){
    this._constructing = true;
    page.audio_controls.play(this.construction_audio, 'started');
  }
}
