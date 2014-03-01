/* Omega JS Session Validator
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// Session Validator Mixins, provides the methods index page
/// uses and probably most other pages will need concerning
/// post-session validation (both for valid & invalid sessions)
///
/// Assumes the class it is being mixed into:
///   - has a node property   (Omega.Node instance)
///   - has a canvas property (Omega.UI.canvas instance)
///   - has a command tracker property (Omega.UI.CommandTracker instance)
///   - has a config property (Omega.Config)
///   - has a nav property
///   - optionally has a session property (Omega.Session instance)
Omega.UI.SessionValidator = {

  /// Restore session and validate invoking the callback corresponding to the
  /// post-validation state
  validate_session : function(validated_cb, invalid_cb){
    var _this = this;
    this.session = Omega.Session.restore_from_cookie();
    /// TODO split out anon user session into third case where we: (?)
    /// - show login controls, load default entities
    if(this.session != null && this.session.user_id != this.config.anon_user){
      this.session.validate(this.node, function(result){
        if(result.error){
          _this._session_invalid(invalid_cb);
        }else{
          _this._session_validated(validated_cb);
        }
      });
    }else{
      _this._session_invalid(invalid_cb);
    }
  },

  _session_validated : function(cb){
    this.nav.show_logout_controls();
    this.canvas.controls.missions_button.show();

    /// refresh entity container, no effect if hidden / entity doesn't belong
    /// to user, else entity controls will now be shown
    this.canvas.entity_container.refresh();

    /// setup callback handlers
    this._handle_events();

    if(cb) cb();
  },

  _session_invalid : function(cb){
    var _this = this;

    if(_this.session) _this.session.clear_cookies();
    _this.session = null;
    this.nav.show_login_controls();

    // login as anon
    var anon = new Omega.User({id : this.config.anon_user,
                               password : this.config.anon_pass});
    Omega.Session.login(anon, this.node, function(result){
      if(result.error){
        //_this.dialog.show_critical_error_dialog();
      }else{
        /// setup callback handlers
        _this._handle_events();
        /// TODO if current scene is set, refresh scene entity tracking

        if(cb) cb();
      }
    });
  },

  /// Helper to register handlers for all supported events
  _handle_events : function(){
    var events = Omega.UI.CommandTracker.prototype.motel_events.concat(
                 Omega.UI.CommandTracker.prototype.manufactured_events);
    for(var e = 0; e < events.length; e++)
      this.command_tracker.track(events[e]);
  },

  /// Return bool indicating if an autologin user is configured
  _should_autologin : function(){
    return !!(this.config.autologin);
  },

  /// Autologin configured user
  autologin : function(cb){
    var _this = this;
    var un    = this.config.autologin[0];
    var pass  = this.config.autologin[1];
    var user  = new Omega.User({id : un, password: pass});
    Omega.Session.login(user, this.node, function(result){
      /// assuming autologin will always success or err is handled elsewhere
      if(!result.error){
        _this.session = result;
        _this._session_validated(cb);
      }
    });
  }
};
