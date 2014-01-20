/* Omega Station Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationInteraction = {
  // XXX not a big fan of having this here, should eventually be moved elsewhere
  dialog : function(){
    if(typeof(this._dialog) === "undefined")
      this._dialog = new Omega.UI.CommandDialog();
    return this._dialog;
  },

  _construct : function(page){
    var _this = this;

    /// TODO parameterize entity type/init!
    /// TODO generate random location in vicity of station and/or allow user
    /// to set a generation point around which new entities appear (within
    /// construction distance of station of course)
    page.node.http_invoke('manufactured::construct_entity',
      this.id, 'entity_type', 'Ship', 'type', 'mining', 'id', RJR.guid(),
      function(response){
        if(response.error){
          _this.dialog().title = 'Construction Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }//else{
           /// entity added to scene, resources updated, entity_container
           /// refreshed and other operations done in construction event callbacks
           //var station = response.result[0];
           //var ship    = response.result[1];
         //}
      });
  },

}
