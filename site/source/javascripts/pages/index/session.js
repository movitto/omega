/* Omega JS Index Page Session Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.IndexSession = {
  _valid_session : function(){
    var _this = this;

    this.nav.show_logout_controls();
    this.canvas.controls.missions_button.show();

    /// refresh entity container, no effect if hidden / entity doesn't belong
    /// to user, else entity controls will now be shown
    this.canvas.entity_container.refresh();

    /// setup callback handlers
    this._handle_events();

    /// track user events
    this.track_user_events(this.session.user_id);

    Omega.UI.Loader.load_universe(this, function(){
      Omega.UI.Loader.load_user_entities(_this.session.user_id, _this.node,
        function(entities) {
          _this.process_entities(entities);
          if(_this._should_autoload_root())
            _this.autoload_root();
        });
    });
  },

  _invalid_session : function(){
    var _this = this;

    if(this.session) this.session.clear_cookies();
    this.session = null;

    this.nav.show_login_controls();

    this._login_anon(function(){
      Omega.UI.Loader.load_universe(_this, function(){
        Omega.UI.Loader.load_default_systems(_this,
          function(solar_system) {
            _this.process_system(solar_system);
            /// FIXME should be invoked after we get _all_ default systems
            if(_this._should_autoload_root())
              _this.autoload_root();
          });
      });
    });
  },

  _login_anon : function(cb){
    var _this = this;

    // login as anon
    var anon = new Omega.User({id : Omega.Config.anon_user,
                               password : Omega.Config.anon_pass});
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
  }
};
