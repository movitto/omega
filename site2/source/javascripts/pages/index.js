/* Omega Index Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/effects_player"
//= require "ui/status_indicator"
//= require "ui/canvas"

// TODO rename to Omega.Pages.Index.Nav ? (same w/ Dialog below)
Omega.UI.IndexNav = function(parameters){
  this.register_link = $('#register_link');
  this.login_link    = $('#login_link');
  this.logout_link   = $('#logout_link');
  this.account_link  = $('#account_link');

  /// need handle to page to
  /// - interact w/ dialog (login/register forms)
  /// - logout of session
  /// - logout using node
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.IndexNav.prototype = {
  wire_up : function(){
    var _this = this;
    this.login_link.click(function(evnt)   {    _this._login_clicked(evnt); });
    this.logout_link.click(function(evnt)  {   _this._logout_clicked(evnt); });
    this.register_link.click(function(evnt){ _this._register_clicked(evnt); });
  },

  show_login_controls : function(){
    this.register_link.show();
    this.login_link.show();
    this.account_link.hide();
    this.logout_link.hide();
  },

  show_logout_controls : function(){
    this.account_link.show();
    this.logout_link.show();
    this.register_link.hide();
    this.login_link.hide();
  },

  _login_clicked : function(evnt){
    this.page.dialog.show_login_dialog();
  },

  _logout_clicked : function(evnt){
    this.page.session.logout(this.page.node);
    this.show_login_controls();
  },

  _register_clicked : function(evnt){
    this.page.dialog.show_register_dialog();
  }
};

Omega.UI.IndexDialog = function(parameters){
  /// need handle to page to
  /// - submit login via node
  /// - set the page session
  /// - update the page nav
  /// - retrieve recaptcha from page config
  /// - submit registration via node
  this.page = null;

  $.extend(this, parameters);

  this.login_button    = $('#login_button');
  this.register_button = $('#register_button');
};

Omega.UI.IndexDialog.prototype = {
  wire_up : function(){
    var _this = this;
    this.login_button.click(function(evnt)   {           _this._login_clicked(evnt); });
    this.register_button.click(function(evnt){ _this._register_button_clicked(evnt); });
  },

  show_login_dialog : function(){
    this.hide();
    this.title   = 'Login';
    this.div_id  = '#login_dialog';
    this.show();
  },

  show_register_dialog : function(){
    this.hide();
    this.title   = 'Register';
    this.div_id  = '#register_dialog';

    Recaptcha.create(this.page.config.recaptcha_pub, 'omega_recaptcha',
      { theme: "red", callback: Recaptcha.focus_response_field});

    this.show();
  },

  show_login_failed_dialog : function(err){
    this.hide();
    this.title   = 'Login Failed';
    this.div_id  = '#login_failed_dialog';
    $('#login_err').html('Login Failed: ' + err);
    this.show();
  },

  show_registration_submitted_dialog : function(){
    this.hide();
    this.title = 'Registration Submitted';
    this.div_id = '#registration_submitted_dialog';
    this.show();
  },

  show_registration_failed_dialog : function(err){
    this.hide();
    this.title = 'Registration Failed';
    this.div_id = '#registration_failed_dialog';
    $('#registration_err').html('Failed to create account: ' + err)
    this.show();
  },

  _login_clicked : function(evnt){
    var user_id  = $('#login_username').val();
    var password = $('#login_password').val();
    var user = new Omega.User({id: user_id, password: password});

    var _this = this;
    Omega.Session.login(user, this.page.node, function(result){
      if(result.error){
        _this.show_login_failed_dialog(result.error.message);
      }else{
        _this.hide();
        _this.page.session = result;
        _this.page._session_validated();
      }
    });
  },

  _register_button_clicked : function(evnt){
    var user_id       = $('#register_username').val();
    var user_password = $('#register_password').val();
    var user_email    = $('#register_email').val();
    var recaptcha_challenge = Recaptcha.get_challenge();
    var recaptcha_response  = Recaptcha.get_response();
    var user = new Omega.User({id: user_id, password: user_password, email: user_email,
                               recaptcha_challenge: recaptcha_challenge,
                               recaptcha_response : recaptcha_response});

    var _this = this;
    this.page.node.http_invoke('users::register', user, function(result){
      if(result.error){
        _this.show_registration_failed_dialog(result.error.message);
      }else{
        _this.show_registration_submitted_dialog();
      }
    });
  }
};

$.extend(Omega.UI.IndexDialog.prototype,
         new Omega.UI.Dialog());

Omega.Pages.Index = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.entities = {};

  this.command_tracker = new Omega.UI.CommandTracker({page : this})

  var _this = this;
  this.session = Omega.Session.restore_from_cookie();
  if(this.session != null){
    this.session.validate(this.node, function(result){
      if(result.error){
        _this.session = null;
        _this.nav.show_login_controls();
      }else{
        _this.session_validated();
      }
    });
  }

  /// not blocking for validation to return,
  /// assuming it'll arrive before node is used above

  //this.effects_player   = new Omega.UI.EffectsPlayer();
  this.dialog           = new Omega.UI.IndexDialog({page : this});
  this.nav              = new    Omega.UI.IndexNav({page : this});
  this.canvas           = new       Omega.UI.Canvas({page: this});
  this.status_indicator = new          Omega.UI.StatusIndicator();

  /// FIXME play status_indicator
  this.status_indicator.follow_node(this.node);
};

Omega.Pages.Index.prototype = {
  // entity getter / setter
  // specify id of entity to get & optional new value to set
  entity : function(){
    if(arguments.length > 1)
      this.entities[arguments[0]] = arguments[1];
    return this.entities[arguments[0]];
  },

  wire_up : function(){
    this.nav.wire_up();
    this.dialog.wire_up();
    this.canvas.wire_up();
  },

  _session_validated : function(){
    var _this = this;
    this.nav.show_logout_controls();

    /// handle scene changes
    this.canvas.handleEvent('set_scene_root',
      function(root_entity){ _this._scene_change(root_entity); })

    /// load entities owned by user
    Omega.Ship.owned_by(this.session.user_id, this.node,
      function(ships) { _this.process_entities(ships); });
    Omega.Station.owned_by(this.session.user_id, this.node,
      function(stations) { _this.process_entities(stations); });
  },

  _scene_change : function(change){
    var root = change.root;
    var old_root = change.old_root;

    var _this = this;
    /// assuming user owned entities are always tracked, do not to be manipulated here
    var entities =
      $.grep(this.entities, function(entity){
        return (entity.json_class == 'Manufactured::Ship' ||
                entity.json_class == 'Manufactured::Station' ) &&
                !entity.belongs_to_user(_this.session.user_id); });
    var in_system =
      $.grep(entities, function(entity){
        return entity.parent_id == root.id; })

    var not_in_system =
      $.grep(entities, function(entity){
        return entity.parent_id != root.id; })

    /// remove tracking of entities not in system
    for(var e = 0; e < not_in_system.length; e++){
      var entity = not_in_system[e];
      if(entity.json_class == 'Manufactured::Ship')
        this.stop_tracking_ship(entity);
      else
        this.stop_tracking_station(entity);
    }

    /// track entities in system
    for(var e = 0; e < in_system.length; e++){
      var entity = in_system[e];
      if(entity.json_class == 'Manufactured::Ship')
        this.track_ship(entity);
      else
        this.track_station(entity);
    }

    /// remove tracking of old planets
    if(old_root.json_class == 'Cosmos::Entities::SolarSystem'){
      for(var p = 0; p < old_root.planets.length; p++){
        var planet = old_root.planets[p];
        this.stop_tracking_planet(planet);
      }
    }

    /// track planets in new system if applicable
    if(root.json_class == 'Cosmos::Entities::SolarSystem'){
      for(var p = 0; p < root.planets.length; p++){
        var planet = root.planets[p];
        this.track_planet(planet);
      }
    }
  },

  handle_events : function(){
    var events = Omega.UI.CommandTracker.prototype.motel_events +
                 Omega.UI.CommandTracker.prototype.manufactured_events;
    for(var e = 0; e < events.length; e++)
      this.command_tracker.track(events[e]);
  },

  process_entities : function(entities){
    /// setup callback handlers
    this.handle_events();

    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  process_entity : function(entity){
    this.entity(entity.id, entity);
    var item   = {id: entity.id, text: entity.id, data: entity};
    this.canvas.controls.entities_list.add(item);

/// FIXME skip if already retrieved from server, (also galaxy below)
/// also some persistent caching mechanism so data doesn't
/// have to be retrieved on each page request
    var _this = this;
    Omega.SolarSystem.with_id(entity.system_id, this.node,
      function(solar_system) { _this.process_system(solar_system) });

    if(entity.json_class == 'Manufactured::Ship')
      this.track_ship(entity);
    else if(entity.json_class == 'Manufactured::Station')
      this.track_station(entity);
  },

  track_ship : function(entity){
    var distance = this.config.ship_movement;
    var rotation = this.config.ship_rotation;

    /// track strategy,stops,movement,rotation
    this.node.ws_invoke('motel::track_strategy', entity.location.id);
    this.node.ws_invoke('motel::track_stops',    entity.location.id);
    this.node.ws_invoke('motel::track_movement', entity.location.id, distance);
    this.node.ws_invoke('motel::track_rotation', entity.location.id, rotation);

    /// track mining, offense, defense
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'resource_collected');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'mining_stopped');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'attacked');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'attacked_stop');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'defended');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'defended_stop');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'destroyed_by');
  },

  stop_tracking_ship : function(entity){
    this.node.ws_invoke('motel::remove_callbacks', entity.location.id);
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  },

  track_station : function(entity){
    /// TODO track jumps
    /// track construction
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'construction_complete');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'partial_construction');
  },

  stop_tracking_station : function(entity){
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  },

  track_planet : function(entity){
    /// TODO
  },

  stop_tracking_planet : function(){
    /// TODO
  },

  process_system : function(system){
    if(system != null){
      var sitem  = {id: system.id, text: system.name, data: system};
      this.canvas.controls.locations_list.add(sitem);

      // TODO load jump gate endpoints?
      var _this = this;
      Omega.Galaxy.with_id(system.parent_id, this.node,
        function(galaxy) { _this.process_galaxy(galaxy) });
    }
  },

  process_galaxy : function(galaxy){
    if(galaxy != null){
      var gitem  = {id: galaxy.id, text: galaxy.name, data: galaxy};
      this.canvas.controls.locations_list.add(gitem);
    }
  }
};

$(document).ready(function(){
//FIXME needs to be enabled for app, disabled for tests
//  var index = new Omega.Pages.Index();
//  index.wire_up();
//  index.canvas.setup();
});
