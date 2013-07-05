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

/* Internal helper to login as anon and invoke callback
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
  node.add_handler('users::on_message', function(msg){
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
 */
var process_entities = function(ui, node, entities){
  // set user owned entities in account info
  var uowned = $.grep(entities, function(e) {
    return e.belongs_to_current_user();
  });
  ui.account_info.entities(uowned);

  for(var e in entities)
    process_entity(ui, node, entities[e]);
};

/* Internal helper to process a single manufactured entity
 */
var process_entity = function(ui, node, entity){
  // store or update in registry
  var rentity = Entities().get(entity.id);
  if(rentity == null){
    Entities().set(entity.id, entity);
  }else{
    rentity.update(entity);
    entity = rentity;
  }

  // store location in registry
  Entities().set(entity.location.id, entity.location);

  ui.entities_container.add_item({ item : entity,
                                   id   : "entities_container-" + entity.id,
                                   text : entity.id });
  ui.entities_container.show();

  // wire up entity page events
  handle_events(ui, node, entity);

  // TODO remove old callback

  // remove from scene on jumping
  entity.on('jumped', function(e, os, ns){
    ui.canvas.scene.remove_entity(e.id)
    ui.canvas.scene.animate();
  });

  // track all applicable server side events, update entity
  Events.track_movement(entity.location.id,
                        $omega_config.ship_movement,
                        $omega_config.ship_rotation);
  entity.location.on(['motel::on_movement',
                      'motel::on_rotation',
                      'motel::location_stopped'],
                      function(){ motel_event(ui, node, arguments); });

  Events.track_construction(entity.id);
  Events.track_mining(entity.id);
  Events.track_offense(entity.id);
  Events.track_defense(entity.id);
  entity.on('manufactured::event_occurred',
            function(){ manufactured_event(ui, node, arguments)});

  // retrieve system and galaxy which entity is in
  load_system(entity.system_id, ui, node, function(sys){
    entity.solar_system = sys;

    // if system currently displayed on canvas, add to scene if not present
    // TODO is this needed?
    if(ui.canvas.scene.get() &&
       ui.canvas.scene.get().id == sys.id){
      ui.canvas.scene.add_new_entity(entity);
      ui.canvas.scene.animate();
    }
  });
}

/* Internal helper to refresh entity container
 */
var refresh_entity_container = function(ui, node, entity){
  // populate entity container w/ details from entity
  ui.entity_container.contents.clear();
  ui.entity_container.contents.add_text(entity.details())

  ui.entity_container.show();
}

/* Callback invoked on motel related event
 */
var motel_event = function(ui, node, eargs){
  // update entity owning location
  //var oloc = eargs[0];
  var nloc = eargs[1];
  var entity =
    Entities().select(function(e){ return e.location && e.location.id == nloc.id })[0];
  entity.update({location : nloc});

  // refresh scene if contains entity
  if(ui.canvas.scene.has(entity.id))
    ui.canvas.scene.animate();

  // refresh popup if showing entity
  var selected = Entities().select(function(e){ return e.selected; })[0]
  if(selected == entity) refresh_entity_container(ui, node, entity);
};

/* Callback to be invoked on manufactured related event
 */
var manufactured_event = function(ui, node, eargs){
  var evnt = eargs[1];

  if(evnt == "resource_collected"){
    var ship            = eargs[2];
    var resource_source = eargs[3];
    var quantity        = eargs[3];

    var rship = Entities().get(ship.id);

    rship.update(ship);
    if(ui.canvas.scene.has(ship.id))
      ui.canvas.scene.animate();

  }else if(evnt == "mining_stopped"){
    var reason = eargs[2];
    var ship   = eargs[3];

    var rship = Entities().get(ship.id);
    ship.mining  = null; // XXX hack serverside ship.mining might
                         // not be nil at this point

    rship.update(ship);
    if(ui.canvas.scene.has(ship.id))
      ui.canvas.scene.animate();

  }else if(evnt == "attacked"){
    var attacker = eargs[2];
    var defender = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    attacker.attacking = rdefender;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "attacked_stop"){
    var attacker = eargs[2];
    var defender = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    attacker.attacking = null;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "defended"){
    var attacker = eargs[2];
    var defender = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    attacker.attacking = rdefender;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "defended_stop"){
    var attacker = eargs[2];
    var defender = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    attacker.attacking = null;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas.scene.has(attacker.id) ||
       ui.canvas.scene.has(defender.id))
      ui.canvas.scene.animate();

  }else if(evnt == "destroyed"){
    var attacker = eargs[2];
    var defender = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    attacker.attacking = null;

    rattacker.update(attacker);
    rdefender.update(defender);

    // remove entity from scene
    ui.canvas.scene.remove_entity(rdefender.id)
    if(ui.canvas.scene.has(attacker.id))
      ui.canvas.scene.animate();

  }else if(evnt == "construction_complete"){
    var station = eargs[2];
    var entity  = eargs[3];

    // retrieve full entity from server
    Ship.with_id(entity.id, function(entity){
      // store in registry
      Entities().set(entity.id, new Ship(entity));

      // process
      process_entity(ui, node, entity);
    });
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
    clicked_entity(ui, node, e);
  });
}

/* Internal helper to handle entity click
 */
var clicked_entity = function(ui, node, entity){
  // unselect currently selected entity
  var selected = Entities().select(function(e){ return (e.id != entity.id) && e.selected; })[0]
  if(selected) ui.canvas.scene.unselect(selected.id);

  if(entity.json_class == "Cosmos::SolarSystem"){
    clicked_system(ui, node, entity);

  }else{
    popup_entity_container(ui, node, entity);

    if(entity.json_class == "Cosmos::Asteroid"){
      clicked_asteroid(ui, node, entity);

    }else if(entity.json_class == "Manufactured::Ship"){
      clicked_ship(ui, node, entity);

    }else if(entity.json_class == "Manufactured::Station"){
      clicked_station(ui, node, entity);
    }
  }
}

/* Internal helper to popup entity container
 */
var popup_entity_container = function(ui, node, entity){
  // setup the entity container
  ui.entity_container.clear_callbacks();
  ui.entity_container.on('hide', function(e){
    // unselect entity in scene
    ui.canvas.scene.unselect(entity.id);

    // always hide the dialog when hiding entity
    ui.dialog.hide();

  })
  entity.on('unselected', function(e){
    // hide entity container
    if(ui.entity_container.visible())
      ui.entity_container.hide();
  })

  // populate entity container w/ details from entity
  ui.entity_container.contents.clear();
  ui.entity_container.contents.add_text(entity.details())

  ui.entity_container.show();
}

/* Internal helper to handle click solar system event
 */
var clicked_system = function(ui, node, solar_system){
  set_scene(ui, solar_system);
}

/* Internal helper to handle click asteroid event
 */
var clicked_asteroid = function(ui, node, asteroid){
  // refresh resources
  node.web_request('cosmos::get_resources', asteroid.id,
    function(res){
      if(res.error == null){
        var details = [{ id : 'resources_title', text : 'Resources: <br/>'}];
        for(var r in res.result){
          var res = res.result[r];
          details.push({ id   : res.id, 
                         text : res.quantity + " of " +
                                res.material_id +"<br/>"});
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

  // clear callbacks
  var select_cmds =
    ['cmd_move_select', 'cmd_attack_select',
     'cmd_dock_select', 'cmd_mine_select'];
  var finished_select_cmds =
    ['cmd_move', 'cmd_attack',
     'cmd_dock', 'cmd_mine']
  var reload_cmds = ['cmd_dock', 'cmd_undock'];
  ship.clear_callbacks(select_cmds);
  ship.clear_callbacks(finished_select_cmds);
  ship.clear_callbacks(reload_cmds);

  // wire up ship commands requiring additional input (use dialog for this)
  ship.on(select_cmds,
    function(cmd, sh, title, content){
      ui.dialog.title    = title;
      ui.dialog.text     = content;
      ui.dialog.selector = null;
      ui.dialog.show();
    });

  // wire up commands which should close ui
  ship.on(finished_select_cmds,
    function(cmd, sh){
      ui.dialog.hide();
      ui.canvas.scene.animate();
    });

  // wire up commands which should reload entity
  ship.on(reload_cmds,
    function(cmd, sh){
      ui.canvas.scene.reload_entity(sh);
    });

  // when selecting mining target, query resources
  // XXX not ideal place to put this, but better than others
  ship.on('cmd_mine_select',
    function(cmd, sh){
      // load mining target selection from asteroids in the vicinity
      var entities = Entities().select(function(e) {
        return e.json_class == 'Cosmos::Asteroid' &&
               e.location.is_within(100, sh.location);
      });

      for(var e in entities){
        var entity = entities[e];
        // remotely retrieve resource sources
        node.web_request('cosmos::get_resource_sources', entity.id,
          function(res){
            if(!res.error){
              for(var r in res.result){
                var res    = res.result[r];
                var restxt = res.material_id + " (" + res.quantity + ")";
                var text   =
                  '<span id="cmd_mine_' + res.id +
                   '" class="cmd_mine dialog_cmds">'+
                     restxt + '</span><br/>';

                // add to dialog
                ui.dialog.append(text);
              }
            }
          })
      }
    });


};

/* Internal helper to handle clicked station event
 */
var clicked_station = function(ui, node, station){
  // currently these events only apply to those w/ modify privs on the station
  if(!station.belongs_to_current_user()) return;

  // add entity to scene on construction
  //station.on('cmd_construct',
  //  function(st, entity){
  //});
};

/* Internal helper to load system
 */
var load_system = function(id, ui, node, callback){
  // XXX use a global to store callbacks for systems
  // which we have requested but not yet retrieved
  if(typeof $system_callbacks === "undefined")
    $system_callbacks = {}
  if(typeof $system_callbacks[id] === "undefined")
    $system_callbacks[id] = []

  var entity =
    Entities().cached(id, function(c){
      // load from server
      SolarSystem.with_id(c, function(s){
        for(var cb in $system_callbacks[s.id])
          $system_callbacks[s.id][cb].apply(s, [s]);
        $system_callbacks[s.id] = [];

        // store system in the registry
        Entities().set(s.id, s);

        // show in the locations container
        ui.locations_container.add_item({ item : s,
                                          id   : "locations_container-" + s.id,
                                          text : s.id });
        ui.locations_container.show();

        // wire up asteroid, jump gate events
        handle_events(ui, node, s.asteroids);
        handle_events(ui, node, s.jump_gates);

        // store planet in registy
        for(var p in s.planets){
          var planet = s.planets[p];
          Entities().set(planet.id, planet);
          Entities().set(planet.location.id, planet.location);
        }

        // store asteroids in registry
        for(var a in s.asteroids){
          var ast = s.asteroids[a];
          Entities().set(ast.id, ast);
        }

        // store jump gates in registry & load endpoints
        for(var j in s.jump_gates){
          var jg = s.jump_gates[j];
          Entities().set(jg.id, jg);
          (function(jg){ // XXX need closure to preserve jg during async request
            load_system(jg.endpoint, ui, node, function(jgs){
              if(jgs.json_class == 'Cosmos::SolarSystem'){
                jg.endpoint_system = jgs;
                s.add_jump_gate(jg, jgs);
              }
            });
          })(jg);
        }

        // retrieve galaxy
        load_galaxy(s.galaxy_id, ui, node, function(g){
          s.galaxy = g;

          // overwrite system in galaxy.solar_systems
          for(var sys in g.solar_systems){
            if(g.solar_systems[sys].id == s.id){
              g.solar_systems[sys] = s;
              break;
            }
          }
        })
      });

     // XXX so as to handle multiple parallal invocations of load_system
     // while we are waiting for remote retrieval
      return -1;
    });

  if(entity != -1)
    callback.apply(null, [entity]);
  else
    $system_callbacks[id].push(callback);
}

/* Internal helper to load galaxy
 */
var load_galaxy = function(id, ui, node, callback){
  // XXX use a global to store callbacks for systems
  // which we have requested but not yet retrieved
  if(typeof $galaxy_callbacks === "undefined")
    $galaxy_callbacks = [];
  if(typeof $galaxy_callbacks[id] === "undefined")
    $galaxy_callbacks[id] = []

  // load from server
  var entity =
    Entities().cached(id, function(c){
      Galaxy.with_id(c, function(g){
        for(var cb in $galaxy_callbacks[g.id])
          $galaxy_callbacks[g.id][cb].apply(g, [g]);
        $galaxy_callbacks[g.id] = []

        // store galaxy in registry
        Entities().set(g.id, g);

        // swap systems in
        // right now we only set those retrieved from the server
        for(var sys in this.solar_systems){
          var rsys = Entities().get(this.solar_systems[sys].id)
          if(rsys && rsys != -1) this.solar_systems[sys] = rsys;
        }

        // wire up solar system events
        handle_events(ui, node, g.solar_systems);

        // show in the locations container
        ui.locations_container.add_item({ item : g,
                                          id   : "locations_container-" + g.id,
                                          text : g.id });
        ui.locations_container.show();
      });

      // XXX same hack as in load_system above
      return -1;
    });

  if(entity != -1)
    callback.apply(null, [entity]);
  else
    $galaxy_callbacks[id].push(callback);
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
         // XXX populate the recaptcha underneath the dialog
         $('#omega_dialog #omega_recaptcha').html('<div id="registration_recaptcha"></div>');
         Recaptcha.create($omega_config.recaptcha_pub, "registration_recaptcha",
                          { theme: "red", callback: Recaptcha.focus_response_field});
       }
     });

  ui.nav_container.
     register_button.on('click', function(){
       ui.dialog.hide();
       var user_id             = $('#omega_dialog #register_username').attr('value');
       var user_password       = $('#omega_dialog #register_password').attr('value');
       var user_email          = $('#omega_dialog #register_email').attr('value');
       var recaptcha_challenge = Recaptcha.get_challenge();
       var recaptcha_response  = Recaptcha.get_response();

       var user = new User({ id : user_id, password : user_password, email : user_email,
                             recaptcha_challenge : recaptcha_challenge,
                             recaptcha_response : recaptcha_response});

       node.web_request('users::register', user, function(res){
         if(res.error){
           ui.dialog.title    = 'Failed to create account';
           ui.dialog.selector = '#registration_failed_dialog';
           ui.dialog.text     = res.error['message'];
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
    set_scene(ui, i.item);
  });

  // set scene and focus on entity when entity is clicked
  ui.entities_container.on('click_item', function(c, i, e){
    set_scene(ui, i.item.solar_system, i.item.location);
  });

  // popup dialog w/ missions info when missions button is clicked
  ui.missions_button.on('click', function(e){
    // get latest mission data from server
    Mission.all(function(missions){
      // store missions in the registry
      for(var m in missions)
        Entities().set(missions[m].id, missions[m]);

      show_missions(missions, ui);
    })
  });

  // assign mission when assign link is clicked in popup dialog
  $('.assign_mission').live('click', function(e){
    var i = e.currentTarget.id;
    Commands.assign_mission(i, Session.current_session.user_id, function(m){
      if(m.error){
        ui.dialog.title    = 'Could not assign mission';
        ui.dialog.text     = m.error.message;
        ui.dialog.show();
      }else{
        Entities().get(m.result.id).update(m.result);
        ui.dialog.hide();
      }
    });
  });
};

/* Internal helper to set scene
 */
var set_scene = function(ui, entity, location){
  // hide dialog
  ui.dialog.hide();

  // unselect selected item
  var selected = Entities().select(function(e){ return (e.id != entity.id) && e.selected; })[0]
  if(selected) ui.canvas.scene.unselect(selected.id);

  // remove old skybox
  ui.canvas.scene.remove_component(ui.canvas.scene.skybox.components[0]);

  // remove old entities
  ui.canvas.scene.clear_entities();

  // set root entity
  ui.canvas.scene.set(entity);

  // focus on location if specified
  if(location) ui.canvas.scene.camera.focus(location);

  // set new skybox background
  ui.canvas.scene.skybox.background(entity.background)

  // add new skybox
  ui.canvas.scene.add_component(ui.canvas.scene.skybox.components[0]);

  // track planet movement
  // TODO remove callbacks of planets in old system
  if(entity.json_class == "Cosmos::SolarSystem"){
    for(var p in entity.planets){
      var planet = entity.planets[p];
      Events.track_movement(planet.location.id, $omega_config.planet_movement);
      var events = ['motel::on_movement',
                    'motel::on_rotation',
                    'motel::location_stopped']
      planet.clear_callbacks(events);
      planet.location.on(events, function(){ motel_event(ui,node,arguments);});
    }
  }
}

/* Internal helper to show missions dialog
 */
var show_missions = function(missions, ui){
  // grab various mission subsets
  var unassigned = $.grep(missions,
                          function(m) { return !m.assigned_to_id && !m.expired(); });
  var assigned   = $.grep(missions,
                          function(m) { return m.assigned_to_current_user(); });
  var victorious = $.grep(assigned,
                          function(m) { return m.victorious; });
  var failed     = $.grep(assigned,
                          function(m) { return m.failed; });
  var current    = $.grep(assigned,
                          function(m) { return !m.victorious && !m.failed; })[0];


  if(current){
    ui.dialog.title    = 'Assigned Mission'
    ui.dialog.text     = '<b>' + current.title         + '</b><br/>' +
                         current.description   + '<br/><hr/>' +
                         '<b>Assigned</b>: ' + current.assigned_time + '<br/>' +
                         '<b>Expires</b>: ' + current.expires().toString();
    ui.dialog.selector = null;

  }else{
    var missions_text = '';
    for(var m in unassigned)
      missions_text += unassigned[m].title + ' ' +
                       unassigned[m].assign_cmd + '<br/>';
    missions_text += '<br/>(Victorious: ' + victorious.length + ' / Failed: ' + failed.length + ')'

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
  ui.canvas.scene.axis.cwire_up();
  ui.canvas.scene.grid.cwire_up();
  ui.entity_container.wire_up();

  // capture window resize and resize canvas
  $(window).resize(function(e){
    if(e.target != window) return;
    var c = ui.canvas;
    c.set_size(($(document).width()  - c.component().offset().left - 50),
               ($(document).height() - c.component().offset().top  - 50));
  });

  // refresh scene whenever texture is loaded
  UIResources().on('texture_loaded', function(t){ ui.canvas.scene.animate(); })

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

    // reset the camera
    ui.canvas.scene.camera.reset();
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
      var message = ui.chat_container.input.component().attr('value');
      var user_id = Session.current_session.user_id;

      node.web_request('users::send_message', message);
      ui.chat_container.output.component().append(user_id + ": " + message + "\n");
      ui.chat_container.input.component().attr('value', '');
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
        var user = ui.account_info.user()
        node.web_request('users::update_user', user,
          function(res){
            if(res.result)
              alert("User " + user.id + " updated successfully");
          });
      }
    });
};

