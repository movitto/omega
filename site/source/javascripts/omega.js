/* Omega Javascript Framework Init
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/config"

//= require "omega/common"
//= require "omega/command"
//= require "omega/registry"
//= require "omega/node"
//= require "omega/entity"
//= require "omega/ui"

//= require "vendor/google_recaptcha_ajax"
//= require 'vendor/jquery.jplayer.min'
//= require 'vendor/jquery.jplayer.playlist.min'

// TODO rather not pass ui, node around everywhere

////////////////////////////////////////// session

/* Public helper to attempt to restore user session
 */
this.restore_session = function(ui, node, cb){
  var session = Session.restore_from_cookie();
  if(session == null){
    login_anon(node, cb);

  }else{
    session.set_headers_on(node);
    session.validate(node, function(result){
      if(result.error){
        login_anon(node);

      }else if(result.result.id != User.anon_user.id){
        session_established(ui, node, session, result.result);
      }
      if(cb) cb();
    });
  }
}

/* Internal helpers to login as anon and invoke callback
 */
var login_anon = function(node, cb){
  Session.login(User.anon_user, node,
                function(session){
                  if(cb) cb();
                });
}

/* Internal helper to be invoked upon a non-anon user
 * session being established
 */
var session_established = function(ui, node, session, user){
  // set node in entities registry
  // XXX don't like this approach but works for now
  Entities().node(node);

  // show logout controls
  ui.nav_container.show_logout_controls();

  // subscribe to chat messages
  if(!node.handlers['users::on_message']) node.handlers['users::on_message'] = [];
  node.handlers['users::on_message'].push(function(msg){
    ui.chat_container.output.append(msg.nick + ": " + msg.message + "\n");
  });
  node.ws_request('users::subscribe_to_messages');

  // show chat
  ui.chat_container.toggle_control().show();

  // show missions button
  ui.missions_button.show();

  // get all entities owned by the user
  Ship.owned_by(user.id,    function(e){ process_entities(ui, node, e); });
  Station.owned_by(user.id, function(e){ process_entities(ui, node, e); });

  // populate account information
  ui.account_info.username(user.id);
  ui.account_info.email(user.email);
  ui.account_info.gravatar(user.email);

  // get stats
  Statistic.with_id('most_entities', 10, process_stats);
}

////////////////////////////////////////// manufactured entities

/* Internal helper to process manufactured entities,
 * eg add them to the ui, retrieve additional related data
 */
var process_entities = function(ui, node, entities){
  // set user owned entities in account info
  var uowned = $.grep(entities, function(e) {
    return e.belongs_to_current_user();
  });
  ui.account_info.entities(uowned);

  for(var e in entities){
    var entity = entities[e];
    ui.entities_container.add_item({ item : entity,
                                     id   : "entities_container-" + entity.id,
                                     text : entity.id });
    ui.entities_container.show();

    // wire up entity page events
    handle_events(ui, node, entity);

    // track all applicable server side events, update entity
    Events.track_movement(entity.location_id,
                          $omega_config.ship_movement,
                          $omega_config.ship_rotation);
    entity.location.on(['motel::on_movement',
                        'motel::on_rotation',
                        'motel::location_stopped'],
                        motel_event);

    Events.track_mining(entity.id);
    Events.track_offense(entity.id);
    Events.track_defense(entity.id);
    entity.on('manufactured::event_occurred',
              manufactured_event);

    // retrieve system and galaxy which entity is in
    load_cosmos('Cosmos::SolarSystem', entity.system_name, ui, node, function(cosmos){
      if(cosmos.json_class == 'Cosmos::SolarSystem')
        entity.solar_system = cosmos;

      if(entity.belongs_to_current_user()){
        ui.locations_container.add_item({ item : cosmos,
                                          id   : "locations_container-" + cosmos.id,
                                          text : cosmos.id });
        ui.locations_container.show();
      }
    });
  }
};

/* Callback invoked on motel related event
 */
var motel_event = function(){
  var loc = arguments[0];
  var entity =
    Entities().select(function(e){ return e.location && e.location.id == loc.id })[0];
  entity.location.update(loc);
  if(ui.canvas.scene.has(entity.id))
    ui.canvas.scene.animate();
};

/* Callback to be invoked on manufactured related event
 */
var manufactured_event = function(){
  var evnt = arguments[0];

  if(evnt == "resource_collected"){
    var ship = arguments[1];
    var resource_source = arguments[2];
    var quantity = arguments[3];

    Entities().get(ship.id).update(ship);
    if(ui.canvas.scene.has(ship.id))
      ui.canvas.scene.animate();

  }else if(evnt == "mining_stopped"){
    var reason = arguments[1];
    var ship   = arguments[2];
    ship.mining  = null; // XXX hack serverside ship.mining might
                         // not be nil at this point

    Entities().get(ship.id).update(ship);
    if(ui.canvas.scene.has(ship.id))
      ui.canvas.scene.animate();

  }else if(evnt == "attacked"){
    var attacker = arguments[1];
    var defender = arguments[2];
    attacker.attacking = defender;

    Entities().get(attacker.id).update(attacker);
    Entities().get(defender.id).update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "attacked_stop"){
    var attacker = arguments[1];
    var defender = arguments[2];
    attacker.attacking = null;

    Entities().get(attacker.id).update(attacker);
    Entities().get(defender.id).update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "defended"){
    var attacker = arguments[1];
    var defender = arguments[2];
    attacker.attacking = defender;

    Entities().get(attacker.id).update(attacker);
    Entities().get(defender.id).update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "defended_stop"){
    var attacker = arguments[1];
    var defender = arguments[2];
    attacker.attacking = null;

    Entities().get(attacker.id).update(attacker);
    Entities().get(defender.id).update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "destroyed"){
    var attacker = arguments[1];
    var defender = arguments[2];
    attacker.attacking = null;

    Entities().get(attacker.id).update(attacker);
    Entities().get(defender.id).update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();
  }

};

/* Internal helper to process stats,
 */
var process_stats = function(stats){
  // add badges to account info
  if(stats.result){
    for(var s in stats.result){
      for(var v in stats.result[s].value){
        if(stats.result[s].value[v] == Session.current_session.user_id){
          ui.account_info.add_badge(stats.result[s].id, stats.result[s].description, v);
          break;
        }
      }
    }
  }
}

////////////////////////////////////////// canvas entities

/* Internal helper to tie various ui entities together through events
 */
var handle_events = function(ui, node, entity){
  if($.isArray(entity)){
    for(var e in entity) handle_events(ui, node, entity[e]);
    return;
  }

  // popup details on click
  entity.on('click', function(e, scene){
    clicked_entity(ui, node, scene, e);

    if(entity.json_class == "Cosmos::Asteroid"){
      clicked_asteroid(ui, node, entity);

    }else if(entity.json_class == "Manufactured::Ship"){
      clicked_ship(ui, node, entity);
      
    }else if(entity.json_class == "Manufactured::Station"){
      clicked_station(ui, node, entity);
    }
  });
}

/* Internal helper to handle any click event
 */
var clicked_entity = function(ui, node, scene, entity){
  // hide entity container so as to unselect previous
  ui.entity_container.hide();

  // setup the entity container
  ui.entity_container.clear_callbacks();
  ui.entity_container.on('hide', function(e){
    // unselect entity in scene
    scene.unselect(e);

    // always hide the dialog when hiding entity
    ui.dialog.hide();
  })

  // populate entity container w/ details from entity
  ui.entity_container.contents.clear();
  ui.entity_container.contents.add_item(e.details)

  ui.entity_container.show();
}

/* Internal helper to handle click asteroid event
 */
var clicked_asteroid = function(ui, node, asteroid){
  // refresh resources
  node.web_request('cosmos::get_resource_sources', e.name,
    function(res){
      if(res.error == null){
        var details = ['Resources: <br/>'];
        for(var r in res.result){
          var res = res.result[r];
          details.push(res.quantity + " of " +
                       res.resource.name +
                       " (" + res.resource.type + ")<br/>");
        }
        ui.entity_container.contents.add_item(details);
      }
    });
};

/* Internal helper to handle clicked ship event
 */
var clicked_ship = function(ui, node, ship){
  // currently these events only apply to those w/ modify privs on the ship
  if(!ship.belongs_to_current_user()) return;

  // wire up ship commands requiring additional input (use dialog for this)
  var select_cmds =
    ['cmd_move_select', 'cmd_attack_select',
     'cmd_dock_select', 'cmd_mine_select'];
  entity.clear_callbacks(select_cmds);
  entity.on(select_cmds,
    function(sh, title, content){
      ui.dialog.title    = title;
      ui.dialog.text     = content;
      ui.dialog.selector = null;
      ui.dialog.show();
    });

  var finished_select_cmds =
    ['cmd_move', 'cmd_attack',
     'cmd_dock', 'cmd_mine']
  entity.clear_callbacks(finsihed_select_cmds);
  entity.on(finished_select_cmds,
    function(sh){
      ui.dialog.hide();
      ui.canvas.scene.animate();
    });

  var reload_cmds = ['cmd_dock', 'cmd_undock'];
  entity.clear_callbacks(reload_cmds);
  entity.on(reload_cmds,
    function(sh){
      ui.canvas.scene.reload(sh);
    });
};

/* Internal helper to handle clicked station event
 */
var clicked_station = function(ui, node, station){
  // currently these events only apply to those w/ modify privs on the station
  if(!station.belongs_to_current_user()) return;

  // add entity to scene on construction
  entity.on('cmd_construct',
    function(st, entity){
      ui.canvas.scene.add_entity(entity);
  });
};

/* Internal helper to load cosmos entity
 */
var load_cosmos = function(type, name, ui, node, callback){
  // if already loaded cosmos entity, apply callback and return.
  // we need this here as callback won't be invoked otherwise
  var entity = Entities().get(name);
  if(entity){
    callback.apply(null, [entity]);
    return;
  }

  Entities().cached(name, function(c){
    if(type == "Cosmos::SolarSystem"){
      // create a temp system so that subsequent calls to
      // cached return a value while we are still waiting
      // for with_name request to return
      var sys = new SolarSystem({name : name});

      // load from server
      SolarSystem.with_name(c, function(s){
        sys.update(s);
        callback.apply(null, [s]);

        // wire up asteroid, jump gate events
        handle_events(ui, node, s.asteroids);
        handle_events(ui, node, s.jump_gates);

        // track planet movement
        for(var p in s.planets){
          var planet = s.planets[p];
          Events.track_movement(planet.location_id, $omega_config.planet_movement);
          planet.location.on(['motel::on_movement',
                              'motel::on_rotation',
                              'motel::location_stopped'],
                              motel_event);
        }

        // load jump gate endpoints
        for(var jg in s.jump_gates){
          load_cosmos('Cosmos::SolarSystem', jg.endpoint, ui, node, function(jgs){
            if(jgs.json_class == 'Cosmos::SolarSystem'){
              jg.endpoint_system = jgs;
              s.add_jump_gate(jg, jgs);
            }
          });
        }

        // retrieve galaxy
        load_cosmos('Cosmos::Galaxy', s.galaxy_name, ui, node, function(g){
          s.galaxy = g;
          callback.apply(null, [g]);
        })
      });

      return sys;

    }else if(type == "Cosmos::Galaxy"){
      // same comment as w/ temp system above
      var gal = new Galaxy({name : name});

      // load from server
      Galaxy.with_name(c, function(g){
        gal.update(g);
        callback.apply(null, [g]);
      });
      
      return gal;
    }
  });
}

////////////////////////////////////////// ui

/* Public Helper to wire page components together
 */
this.wire_up_ui = function(ui, node){
  wire_up_nav(ui, node);
  wire_up_status(ui, node);
  wire_up_jplayer(ui, node);
  wire_up_entities_lists(ui, node);
  wire_up_canvas(ui, node);
  wire_up_chat(ui, node);
  wire_up_account_info(ui, node);
};

////////////////////////////////////////// nav

/* Internal helper to wire up navigation
 */
var wire_up_nav = function(ui, node){
  // show login dialog on login link click
  ui.nav_container.
     login_link.on('click', function(){
       ui.dialog.title = 'Login';
       ui.dialog.text  = '';
       ui.dialog.selector = '#login_dialog';
       ui.dialog.show();
     });
    
  // login on login dialog submit
  ui.nav_container.
     login_button.on('click', function(){
       ui.dialog.hide();
       var user_id       = ui.dialog.subdiv('#login_username').attr('value');
       var user_password = ui.dialog.subdiv('#login_password').attr('value');
       var user = new User({ id : user_id, password : user_password });
       Session.login(user, node, function(session){
         session_established(ui, node, session, user)
       });
     });

  // show register dialog on register link click
  ui.nav_container.
     register_link.on('click', function(){
       ui.dialog.title = 'Register';
       ui.dialog.text  = '';
       ui.dialog.selector = '#register_dialog';
       ui.dialog.show();

       if($omega_config.recaptcha_enabled){
         $('#omega_recaptcha').html('<div id="registration_recaptcha"></div>');
         Recaptcha.create($omega_config.recaptcha_pub, "registration_recaptcha",
                          { theme: "red", callback: Recaptcha.focus_response_field});
       }
     });
    
  ui.nav_container.
     register_button.on('click', function(){
       ui.dialog.hide();
       var user_id             = $('#register_username').attr('value');
       var user_password       = $('#register_password').attr('value');
       var user_email          = $('#register_email').attr('value');
       var recaptcha_challenge = Recaptcha.get_challenge();
       var recaptcha_response  = Recaptcha.get_response();

       var user = new User({ id : user_id, password : user_password, email : user_email,
                             recaptcha_challenge : recaptcha_challenge,
                             recaptcha_response : recaptcha_response});

       node.web_request('users::register', user, function(res){
         if(res.error){
           ui.dialog.title    = 'Failed to create account';
           ui.dialog.selector = '#registration_failed_dialog';
           ui.dialog.text     = error['message'];
         }

         else{
           ui.dialog.title    = 'Creating Account';
           ui.dialog.selector = '#registration_submitted_dialog';
           ui.dialog.text     = '';
         }

         ui.dialog.show();
       });
     });

  ui.nav_container.
     logout_link.on('click', function(){
       Session.logout(node, function(){
         login_anon(node);
       });

       // hide everything (almost)
       ui.missions_button.hide();
       ui.entities_container.hide();
       ui.locations_container.hide();
       ui.entity_container.hide();
       ui.dialog.hide();
       ui.chat_container.toggle_control().hide();
       ui.chat_container.hide();

       // clean up canvas (TODO possibly move into its own method)
       ui.canvas.scene.clear_entities();
       ui.canvas.scene.skybox.shide();
       ui.canvas.scene.axis.shide();
       ui.canvas.scene.grid.shide();
       ui.canvas.scene.grid.shide();
       ui.canvas.scene.camera.reset();

       ui.nav_container.show_login_controls();
     });
};

////////////////////////////////////////// status indicator

/* Internal helper to wire up status indicator
 */
var wire_up_status = function(ui, node){
  node.on('request', function(node, req){
    ui.status_indicator.push_state('loading');
  });

  node.on('msg_received', function(node, res){
    ui.status_indicator.pop_state();
  });

};

////////////////////////////////////////// jplayer

/* Internal helper to wire up jplayer
 */
var wire_up_jplayer = function(ui, node){
  // TODO dynamic playlist
  var audio_path = "http://" + $omega_config["host"]    +
                               $omega_config["prefix"]  + "/audio";
  var playlist = 
    new jPlayerPlaylist({
          jPlayer: "#jquery_jplayer_1",
          cssSelectorAncestor: "#jplayer_container"},
          [{ title: "track1", wav: audio_path + "/simple2.wav" },
           { title: "track2", wav: audio_path + "/simple4.wav" }],
          {swfPath: "js", supplied: "wav", loop: "true"});
};

////////////////////////////////////////// entities lists

/* Internal helper to wire up entities lists
 */
var wire_up_entities_lists = function(ui, node){
  // set scene when location is clicked
  ui.locations_container.on('click_item', function(c, i, e){
    ui.canvas.scene.set(i.item);
  });

  // set scene and focus on entity when entity is clicked
  ui.entities_container.on('click_item', function(c, i, e){
    ui.canvas.scene.camera.focus(i.item.location);
    ui.canvas.scene.set(i.item.solar_system);
  });

  // popup dialog w/ missions info when missions button is clicked
  ui.missions_button.on('click', function(e){
    // get latest mission data from server
    Mission.all(function(missions){
      if(missions.result){
        show_missions(mission.result, ui);
      }
    })
  });

  // assign mission when assign link is clicked in popup dialog
  $('.assign_mission').live('click', function(e){
    var i = e.currentTarget.id;
    Commands.assign_mission(i, Session.current_session.user_id, function(m){
      Entities().get(m.id).update(m);
    });
    ui.dialog.hide();
  });
};

/* Internal helper to show missions dialog
 */
var show_missions = function(missions, ui){
  // grab mission data or assigned mission
  var assigned = $.grep(missions,
                        function(m) { m.assigned_to_user() &&
                                       !mission.victorious &&
                                       !mission.failed});

  if(assigned){
    ui.dialog.title    = 'Assigned Mission'
    ui.dialog.text     = assigned.title + '<br/>' + assigned.description +
                         '(' + assigned.assigned_time + '/' + assigned.expires().toString() + ')';
    ui.dialog.selector = null;

  }else{
    var missions_text = '';
    for(var m in missions){
      var mission = missions[m];
        if(!mission.expired() && !mission.assigned_to_id){
          missions_text += mission.assign_cmd;
      }
    }

    ui.dialog.title    = 'Missions';
    ui.dialog.text     = missions_text;
    ui.dialog.selector = null;
  }

  // TODO display text for completed missions
  ui.dialog.show();
}

////////////////////////////////////////// canvas

/* Internal helper to wire up the canvas
 */
var wire_up_canvas = function(ui, node){
  // wire up canvas and related components to page
  ui.canvas.wire_up();
  ui.canvas.scene.camera.wire_up();
  ui.canvas.scene.axis.wire_up();
  ui.canvas.scene.grid.wire_up();
  ui.entity_container.wire_up();

  // FIXME capture page resize and resize canvas

  // when setting scene to solar system, get all entities under it
  ui.canvas.scene.on('set', function(s){
    // remove event callbacks of entities in old system not beloning to user
    var old_entities =
      Entities().select(function(e){
        return (s.json_class == 'Manufactured::Ship' || s.json_class == 'Manufactured::Station') &&
               !s.has(e.id) && e.user_id != Session.current_session.user_id;
      })

    for(var e in old_entities){
      var entity = old_entities[e];
      Events.stop_track_movement(entity.location.id);
      Events.stop_track_manufactured(entity.id);
    }
                                                              
    // refresh entities under the system
    if(s.get().json_class == "Cosmos::SolarSystem")
      SolarSystem.entities_under(s.get().name, function(e){ process_entities(ui, node, e); });
  });
}

////////////////////////////////////////// chat

/* Internal helper to wire up chat container
 */
var wire_up_chat = function(ui, node){
  // wire up chat to page
  ui.chat_container.wire_up();

  // send message via node when user clicks send button
  ui.chat_container.
    button.on('click', function(b, e){
      var message = ui.chat_container.input.attr('value');
      var user_id = Session.current_session.user_id;

      node.web_request('users::send_message', message);
      ui.output.append(user_id + ": " + message + "\n");
    });
};

////////////////////////////////////////// account info

/* Internal helper to wire up account info container
 */
var wire_up_account_info = function(ui, node){
  ui.account_info.
    update_button.on('click', function(b, e){
      if(!ui.account_info.passwords_match())
        alert("Passwords do not match");

      else{
        node.web_request('users::update_user', ui.account_info.user(),
          function(res){
            if(res.result)
              alert("User " + user.id + " updated successfully");
          });
      }
    });
};
