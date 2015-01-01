/* Omega Jump Gate Command Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/command_dialog"

Omega.JumpGateCommands = {
  has_details : true,

  retrieve_details : function(page, details_cb){
    var title = 'Jump Gate to ' + this.endpoint_title();
    var loc   = '@ ' + this.location.to_s();
    var trigger_cmd   = $('<span/>',
      {id    : 'trigger_jg_' + this.id,
       class : 'trigger_jg details_command',
       text  : 'trigger'});
    trigger_cmd.data('jump_gate', this);

    var _this = this;
    trigger_cmd.click(function(){ _this._trigger(page); });

    /// exclude trigger_cmd if page.session is null
    var details_text = title + '<br/>' + loc + '<br/><br/>';
    var details = page.session ? [details_text, trigger_cmd] : [details_text];
    details_cb(details);
  },

  dialog : function(){
    return Omega.UI.CommandDialog.instance();
  },

  _trigger : function(page){
    var _this = this;
    var ships = $.grep(page.all_entities(), function(e){
                  return _this._should_trigger_ship(e, page);
                });

    for(var s = 0; s < ships.length; s++)
      this._trigger_ship(ships[s], page);
  },

  _trigger_ship : function(ship, page){
    var _this = this;

    /// FIXME make sure endpoint is set! (won't come in w/ server jg)
    ship.location.parent_id = _this.endpoint.location.id;
    page.node.http_invoke('manufactured::move_entity', ship.id, ship.location,
      function(response){
        if(response.error)
          _this._trigger_ship_failed(response);
        else
          _this._trigger_ship_success(ship, page);
      });
  },

  _trigger_ship_failed : function(response){
    this.dialog().title = 'Jump Gate Trigger Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  _trigger_ship_success : function(ship, page){
    /// FIXME need to set system itself
    ship.system_id = this.endpoint_id;
    page.canvas.remove(ship);
    page.audio_controls.play(this.trigger_audio);
    ship.update_jump_gfx();
  },

  _should_trigger_ship : function(entity, page){
    return entity.json_class == 'Manufactured::Ship' &&
           entity.belongs_to_user(page.session.user_id) &&
           entity.location.is_within(this.trigger_distance,
                                     this.location);
  }
};
