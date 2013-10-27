/* Omega Javascript Containers
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/jquery.timer"

/* Instantiate and return a new Entity Container
 */
function EntityContainer(args){
  $.extend(this, new UIComponent(args));

  this.div_id = '#omega_entity_container';

  //var nargs       = $.extend({container : this}, args);
  this.contents    = new UIListComponent();
  this.contents.div_id = '#entity_container_contents';
  this.subcomponents.push(this.contents);

  this.close_control_id = '#entity_container_close';

  // ensure clicks don't propagate to canvas
  this.component().on('mousedown',  stop_prop);
}

/* Instantiate and return a new Entities Container
 */
function EntitiesContainer(args){
  $.extend(this, new UIComponent(args));

  this.div_id = args['div_id'];

  this.list = new UIListComponent();
  this.list.div_id = this.div_id + ' ul';
  this.list.item_wrapper = 'li';

  // show entities container on hover
  this.on('mouseenter', function(c, e){
    this.list.show();
    //this.component().css('z-index', 1)
  });
  this.on('mouseleave', function(c, e){
    this.list.hide();
  });

  // ensure clicks don't propagate to canvas
  this.list.component().on('mousedown', stop_prop);
}

EntitiesContainer.hide_all = function(){
  var cl = '.entities_container';
  $(cl).hide();

  // XXX we also hide the missions button
  $('#missions_button').hide();
}

/* Instantiate and return a new Status Indicator
 */
function StatusIndicator(args){
  $.extend(this, new UIComponent(args));

  this.div_id       = '#status_icon';

  // stack of states which are currently set
  var states =  [];

  // timer to blink icon
  var _this = this;

  // Helper set icon background
  this.set_bg = function(bg){
    if(bg == null){
      this.component().css('background', '');
      StatusIndicator.bg_timer.stop();
      return;
    }

    this.component().
         css('background',
             'url("http://' +
                  $omega_config['host'] +
                  $omega_config['prefix'] +
                  '/images/status/' + bg + '.png") no-repeat');
    StatusIndicator._instance = this;
    StatusIndicator.bg_timer.play();
  }

  /* Return boolean indicating if state is currently represented locally
   */
  this.has_state = function(state){
    for(var s = 0; s < states.length; s++)
      if(states[s] == state)
        return true;
    return false;
  }

  /* Return boolean indicating if topmost state on stack is the specified state
   */
  this.is_state = function(state){
    if(states.length == 0) return false;
    return states[states.length-1] == state;
  };

  /* Push a new state onto the stack, this updates the status icon background
   */
  this.push_state = function(state){
    states.push(state);
    this.set_bg.apply(this, [state]);
  }

  /* Pop a new state of the stack, this updates the status icon background
   */
  this.pop_state = function(){
    states.pop();
    if(states.length > 0){
      this.set_bg.apply(this, [states[states.length-1]])

    }else{
      this.set_bg.apply(this, [null]);
    }
  }
}

var obg = '';
StatusIndicator.bg_timer = $.timer(function(){
  var si  = StatusIndicator._instance;
  var cbg = si.component().css('background-image');

  if(cbg == '' && obg == ''){
  }else if(obg != ''){
    si.component().css('background', obg)
    obg = '';
  }else{
    obg = cbg;
    si.component().css('background', '')
  }
}, 1000, false)

/* Instantiate and return a new Nav Container
 */
function NavContainer(args){
  $.extend(this, new UIComponent(args));
  this.div_id = '#navigation';

  // navigation components

  this.register_link = new UIComponent();
  this.register_link.div_id = '#register_link';

  this.register_button = new UIComponent();
  this.register_button.div_id = '#register_button';

  this.login_link = new UIComponent();
  this.login_link.div_id = '#login_link';

  this.login_button = new UIComponent();
  this.login_button.div_id = '#login_button';

  this.logout_link = new UIComponent();
  this.logout_link.div_id = '#logout_link';

  this.account_link = new UIComponent();
  this.account_link.div_id = '#account_link';

  this.subcomponents.push(this.register_link)
  this.subcomponents.push(this.login_link)
  this.subcomponents.push(this.logout_link)
  this.subcomponents.push(this.account_link)

  /* Show login controls, hide logout controls
   */
  this.show_login_controls = function(){
    this.register_link.show();
    this.login_link.show();
    this.account_link.hide();
    this.logout_link.hide();
  }

  /* Show logout controls, hide login controls
   */
  this.show_logout_controls = function(){
    this.account_link.show();
    this.logout_link.show();
    this.register_link.hide();
    this.login_link.hide();
  }

  // ensure clicks don't propagate to canvas
  this.login_link.component().on('mousedown', stop_prop);
  this.login_button.component().on('mousedown', stop_prop);
  this.register_link.component().on('mousedown', stop_prop);
  this.register_button.component().on('mousedown', stop_prop);
  this.logout_link.component().on('mousedown', stop_prop);
}

/* Instantiate and return a new Account Info Container
 */
function AccountInfoContainer(args){
  $.extend(this, new UIComponent(args));
  this.div_id = '#account_info';

  this.update_button        = new UIComponent();
  this.update_button.div_id = '#account_info_update';
  this.subcomponents.push(this.update_button);

  /* get/set the username element
   */
  this.username = function(new_username){
    var container = $('#account_info_username input');
    if(new_username)
      container.attr('value', new_username);
    return container.attr('value');
  }

  /* get the password element
   */
  this.password = function(){
    var container = $('#user_password');
    return container.attr('value');
  }

  /* get/set the email element
   */
  this.email = function(new_email){
    var container = $('#account_info_email input');
    if(new_email)
      container.attr('value', new_email);
    return container.attr('value');
  }

  /* get/set the gravatar element from the user email
   */
  this.gravatar = function(user_email){
    var container = $('#account_logo');
    if(user_email){
      var gravatar_url = 'http://gravatar.com/avatar/' + md5(user_email) + '?s=175';
      container.html('<img src="'+gravatar_url+'" alt="gravatar" title="gravatar">');
    }
    return container.html();
  }

  /* set entities lists
   */
  this.entities = function(entities){
    var ships_container    = $('#account_info_ships');
    var stations_container = $('#account_info_stations');
    for(var e = 0; e < entities.length; e++){
      if(entities[e].json_class == 'Manufactured::Ship')
        ships_container.append(entities[e].id + ' ')
      else if(entities[e].json_class == 'Manufactured::Station')
        stations_container.append(entities[e].id + ' ')
    }
  }

  /* return bool indicating if password matches confirmation
   */
  this.passwords_match = function(){
    var pass1 = this.password();
    var pass2 = $('#user_confirm_password').attr('value');
    return pass1 == pass2;
  }

  /* return user generated from account info
   */
  this.user = function(){
    return new User({id    : this.username(),
                     email : this.email(),
                     password: this.password()});
  }

  /* add a badge to account into page
   */
  this.add_badge = function(id, description, rank){
    // display top n badge
    var badges = $('#account_info_badges');
    var btxt = '<div class="badge" style="background: url(\'' +
                  $omega_config.prefix + '/images/badges/' + id +'.png\');">'+
                  description + ': ' + (rank+1)+'</div>';

    badges.append(btxt);
  }
}

// Plays audio and canvas effects
function EffectsPlayer(args){
  var _this = this;
  $.extend(this, args);

  this.div_id = '#effects_jplayer';
  this._player = 
    $(this.div_id).jPlayer({
      cssSelectorAncestor: '#effects_jplayer_container',
      swfPath: "js", supplied: "wav", loop : false
    });

  this.play = function(media){
    if(this.current_media != media){
      this._player.
           jPlayer("setMedia" , { wav: this.path + media });
      this.current_media = media;
    }

    // TODO support audio sprites / starting time param
    this._player.jPlayer("play");
  }

  this.effects_loop = function(){
    /// assumes we have handle to scene
    var objects = this.scene.objects();
    for(var c = 0; c < objects.length; c++){
      var obj = objects[c];
      /// FIXME rename to 'update_effects'
      if(obj.update_particles)
        obj.update_particles();
    }
    this.scene.animate();
  }

  this.start = function(){
    EffectsPlayer._instance = this;
    EffectsPlayer.effects_timer.play();
  };
}

EffectsPlayer.effects_timer =
  $.timer(function(){
    EffectsPlayer._instance.effects_loop();
  }, 250, false);
