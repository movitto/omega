/* Omega Station Construction Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationConstructionInteractions = {
  _set_construction_params : function(page){
    this.dialog().show_construction_dialog(page, this);
  },

  _construct : function(page, args){
    var _this = this;

    var construct_args = ['manufactured::construct_entity', this.id].concat(args);

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
};
