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
//= require "omega/ui"
//= require "omega/entity"
//= require_directory "./entities"

//= require "vendor/google_recaptcha_ajax"
//= require 'vendor/jquery.jplayer-2.4.0.min'
//= require 'vendor/jquery.jplayer.playlist-2.3.0.min'

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
      
      }else{
        if(result.result.id == User.anon_user.id)
          login_anon(node);

        else
          session_established(ui, node, session, result.result);
      }

      if(cb) cb();
    });
  }
}

/* Internal helper to login as anon and invoke callback
 */
var login_anon = function(node, cb){
  Entities().node(node);
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
  if(ui.nav_container)
    ui.nav_container.show_logout_controls();

  // show missions button
  if(ui.canvas_container)
    ui.canvas_container.missions_button.show();

  // get all entities owned by the user
  Ship.owned_by(user.id,    function(e){ process_entities(ui, node, e); });
  Station.owned_by(user.id, function(e){ process_entities(ui, node, e); });

  // populate account information
  if(ui.account_info){
    ui.account_info.username(user.id);
    ui.account_info.email(user.email);
    ui.account_info.gravatar(user.email);
  }

  // get stats
  Statistic.with_id('with_most', ['entities', 10], process_stats);
}

////////////////////////////////////////// manufactured entities

/* Internal helper to process manufactured entities,
 */
var process_entities = function(ui, node, entities){
  // set user owned entities in account info
  var uowned = $.grep(entities, function(e) {
    return e.belongs_to_current_user();
  });
  if(ui.account_info){
    ui.account_info.entities(uowned);
  }

  for(var e = 0; e < entities.length; e++)
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
  Entities().set('location-'+entity.location.id, entity.location);

  if(ui.canvas_container){
    ui.canvas_container.entities_list.
       list.add_item({ item : entity,
                       id   : "entities_container-" + entity.id,
                       text : entity.id });
    ui.canvas_container.entities_list.show();
  }

  // wire up entity page events
  handle_events(ui, node, entity);

  // TODO remove old callback

  // remove from scene on jumping
  entity.on('jumped', function(e, os, ns){
    ui.canvas_container.canvas.scene.remove_entity(e.id)
    ui.canvas_container.canvas.scene.animate();
  });

  // track all applicable server side events, update entity
  Events.track_movement(entity.location.id,
                        $omega_config.ship_movement,
                        $omega_config.ship_rotation);
  entity.location.on(['motel::on_movement',
                      'motel::on_rotation',
                      'motel::location_stopped',
                      'motel::changed_strategy'],
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

    // XXX run update on self to update in any system-dependent
    // entity attributes (such as mining target/line)
    entity.refresh();

    // if system currently displayed on canvas, add to scene if not present
    if(ui.canvas_container &&
       ui.canvas_container.canvas.scene.get() &&
       ui.canvas_container.canvas.scene.get().id == sys.id){
      ui.canvas_container.canvas.scene.add_new_entity(entity);
      ui.canvas_container.canvas.scene.animate();
    }
  });
}

/* Internal helper to refresh entity container
 */
var refresh_entity_container = function(ui, node, entity){
  // populate entity container w/ details from entity
  ui.canvas_container.entity_container.contents.clear();
  ui.canvas_container.entity_container.contents.add_text(entity.details())

  ui.canvas_container.entity_container.show();
}

/* Callback invoked on motel related event
 */
var motel_event = function(ui, node, eargs){
  // update entity owning location
  //var oloc = eargs[0];
  var nloc = eargs[1];
  var entity =
    Entities().select(function(e){ return e.location && e.location.id == nloc.id })[0];
  entity.update({location:nloc});

  // refresh scene if contains entity
  if(ui.canvas_container.canvas.scene.has(entity.id))
    ui.canvas_container.canvas.scene.animate();

  // refresh popup if showing entity
  var selected = Entities().select(function(e){ return e.selected; })[0]
  if(selected == entity) refresh_entity_container(ui, node, entity);
};

/* Callback to be invoked on manufactured related event
 */
var manufactured_event = function(ui, node, eargs){
  var evnt = eargs[1];
  var entities = [];

  if(evnt == "resource_collected"){
    var ship            = eargs[2];
    var resource        = eargs[3];
    var quantity        = eargs[4];

    var rship = Entities().get(ship.id);
    entities.push(rship);

    rship.update(ship);
    if(ui.canvas_container.canvas.scene.has(ship.id))
      ui.canvas_container.canvas.scene.animate();

  }else if(evnt == "mining_stopped"){
    var ship     = eargs[2];
    var resource = eargs[3];
    var reason   = eargs[4];

    var rship = Entities().get(ship.id);
    entities.push(rship);
    ship.mining  = null; // XXX hack serverside ship.mining might
                         // not be nil at this point

    rship.update(ship);
    if(ui.canvas_container.canvas.scene.has(ship.id))
      ui.canvas_container.canvas.scene.animate();

  }else if(evnt == "attacked"){
    var attacker = eargs[2];
    var defender = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    entities.push(rattacker);
    entities.push(rdefender);
    attacker.attacking = rdefender;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas_container.canvas.scene.has(attacker.id) ||
       ui.canvas_container.canvas.scene.has(defender.id))
      ui.canvas_container.canvas.scene.animate();

  }else if(evnt == "attacked_stop"){
    var attacker = eargs[2];
    var defender = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    entities.push(rattacker);
    entities.push(rdefender);
    attacker.attacking = null;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas_container.canvas.scene.has(attacker.id) ||
       ui.canvas_container.canvas.scene.has(defender.id))
      ui.canvas_container.canvas.scene.animate();

  }else if(evnt == "defended"){
    var defender = eargs[2];
    var attacker = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    entities.push(rattacker);
    entities.push(rdefender);
    attacker.attacking = rdefender;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas_container.canvas.scene.has(attacker.id) ||
       ui.canvas_container.canvas.scene.has(defender.id))
      ui.canvas_container.canvas.scene.animate();

  }else if(evnt == "defended_stop"){
    var defender = eargs[2];
    var attacker = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    entities.push(rattacker);
    entities.push(rdefender);
    attacker.attacking = null;

    rattacker.update(attacker);
    rdefender.update(defender);
    if(ui.canvas_container.canvas.scene.has(attacker.id) ||
       ui.canvas_container.canvas.scene.has(defender.id))
      ui.canvas_container.canvas.scene.animate();

  }else if(evnt == "destroyed_by"){
    var defender = eargs[2];
    var attacker = eargs[3];

    var rattacker = Entities().get(attacker.id);
    var rdefender = Entities().get(defender.id);
    entities.push(rattacker);
    entities.push(rdefender);
    attacker.attacking = null;

    rattacker.update(attacker);
    rdefender.update(defender);

    // remove entity from scene
    ui.canvas_container.canvas.scene.remove_entity(rdefender.id)
    if(ui.canvas_container.canvas.scene.has(attacker.id))
      ui.canvas_container.canvas.scene.animate();

  }else if(evnt == "construction_complete"){
    var station = eargs[2];
    var entity  = eargs[3];

    var rstation = Entities().get(station.id);
    entities.push(rstation);

    // retrieve full entity from server
    Ship.with_id(entity.id, function(entity){
      // store in registry
      Entities().set(entity.id, entity);

      // process
      process_entity(ui, node, entity);
    });
  }

  // refresh popup if showing entity
  var selected = Entities().select(function(e){ return e.selected; })[0]
  if(selected){
    for(var e = 0; e < entities.length; e++){
      if(entities[e].id == selected.id){
        refresh_entity_container(ui, node, entities[e]);
        break;
      }
    }
  }
};

/* Internal helper to process stats,
 */
var process_stats = function(stats){
  // add badges to account info
  if(stats.result){
    for(var s = 0; s < stats.result.length; s++){
      for(var v = 0; v < stats.result[s].value.length; v++){
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
    for(var e = 0; e < entity.length; e++)
      handle_events(ui, node, entity[e]);
    return;
  }

  // popup details on click
  entity.clear_callbacks('click');
  entity.on('click', function(e, scene){
    clicked_entity(ui, node, e);
  });
}

/* Internal helper to handle entity click
 */
var clicked_entity = function(ui, node, entity){
  // unselect currently selected entity
  var selected = Entities().select(function(e){ return (e.id != entity.id) && e.selected; })[0]
  if(selected) ui.canvas_container.canvas.scene.unselect(selected.id);

  if(entity.json_class == "Cosmos::Entities::SolarSystem"){
    clicked_system(ui, node, entity);

  }else{
    popup_entity_container(ui, node, entity);

    if(entity.json_class == "Cosmos::Entities::Asteroid"){
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
  ui.canvas_container.entity_container.clear_callbacks();
  ui.canvas_container.entity_container.on('hide', function(e){
    // unselect entity in scene
    ui.canvas_container.canvas.scene.unselect(entity.id);

    // always hide the dialog when hiding entity
    ui.dialog.hide();

  })
  entity.on('unselected', function(e){
    // hide entity container
    if(ui.canvas_container.entity_container.visible())
      ui.canvas_container.entity_container.hide();
  })

  // populate entity container w/ details from entity
  ui.canvas_container.entity_container.contents.clear();
  ui.canvas_container.entity_container.contents.add_text(entity.details())

  ui.canvas_container.entity_container.show();
}

/* Internal helper to handle click solar system event
 */
var clicked_system = function(ui, node, solar_system){
  set_scene(ui, node, solar_system);
}

/* Internal helper to handle click asteroid event
 */
var clicked_asteroid = function(ui, node, asteroid){
  // refresh resources
  node.web_request('cosmos::get_resources', asteroid.id,
    function(res){
      if(res.error == null){
        var details = [{ id : 'resources_title', text : 'Resources: <br/>'}];
        for(var r = 0; r < res.result.length; r++){
          var rres = res.result[r];
          details.push({ id   : rres.id, 
                         text : rres.quantity + " of " +
                                rres.material_id +"<br/>"});
        }  
        ui.canvas_container.entity_container.contents.add_item(details);
      }
    });
};

/* Internal helper to handle clicked ship event
 */
var clicked_ship = function(ui, node, ship){
  // currently these events only apply to those w/ modify privs on the ship
  if(!ship.belongs_to_current_user()) return;

  //ui.effects_player.play("selection.wav")

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
      ui.canvas_container.canvas.scene.animate();
    });

  // wire up commands which should reload entity
  ship.on(reload_cmds,
    function(cmd, sh){
      ui.canvas_container.canvas.scene.reload_entity(sh);
    });

  // when selecting mining target, query resources
  // XXX not ideal place to put this, but better than others
  ship.on('cmd_mine_select',
    function(cmd, sh){
      // load mining target selection from asteroids in the vicinity
      var entities = Entities().select(function(e) {
        return e.json_class == 'Cosmos::Entities::Asteroid' &&
               e.location.is_within(100, sh.location);
      });

      for(var e = 0; e < entities.length; e++){
        var entity = entities[e];
        // remotely retrieve resource sources
        node.web_request('cosmos::get_resources', entity.id,
          function(res){
            if(!res.error){
              for(var r = 0; r < res.result.length; r++){
                var rres    = res.result[r];
                var restxt = rres.material_id + " (" + rres.quantity + ")";
                var text   =
                  '<span id="cmd_mine_' + rres.id +
                   '" class="cmd_mine dialog_cmds">'+
                     restxt + '</span><br/>';

                // add to dialog
                ui.dialog.append(text);
              }
            }
          })
      }
    });

  // on transfer, update the ship/station, refresh entity container
  ship.on('cmd_transfer',
    function(cmd, sh, st){
      ship.update(sh);
      Entities().get(st.id).update(st);
      refresh_entity_container(ui, node, ship);
    });
};

/* Internal helper to handle clicked station event
 */
var clicked_station = function(ui, node, station){
  // currently these events only apply to those w/ modify privs on the station
  if(!station.belongs_to_current_user()) return;
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
        // store system in the registry
        Entities().set(s.id, s);

        // run callbacks
        for(var cb = 0; cb < $system_callbacks[s.id].length; cb++)
          $system_callbacks[s.id][cb].apply(s, [s]);
        $system_callbacks[s.id] = [];

        // show in the locations container
        if(ui.canvas_container){
          ui.canvas_container.locations_list.
             list.add_item({ item : s,
                             id   : "locations_container-" + s.id,
                             text : 'System: ' + s.name });
          ui.canvas_container.locations_list.show();
        }

        // wire up asteroid, jump gate events
        handle_events(ui, node, s.asteroids);
        handle_events(ui, node, s.jump_gates);

        // store planet in registy
        for(var p = 0; p < s.planets.length; p++){
          var planet = s.planets[p];
          Entities().set(planet.id, planet);
          Entities().set('location-' + planet.location.id, planet.location);
        }

        // store asteroids in registry
        for(var a = 0; a < s.asteroids.length; a++){
          var ast = s.asteroids[a];
          Entities().set(ast.id, ast);
        }

        // store jump gates in registry & load endpoints
        for(var j = 0; j < s.jump_gates.length; j++){
          var jg = s.jump_gates[j];
          Entities().set(jg.id, jg);
          (function(jg){ // XXX need closure to preserve jg during async request
            load_system(jg.endpoint_id, ui, node, function(jgs){
              if(jgs.json_class == 'Cosmos::Entities::SolarSystem'){
                jg.endpoint_system = jgs;
                s.add_jump_gate(jg, jgs);
              }
            });
          })(jg);
        }

        // retrieve galaxy
        load_galaxy(s.parent_id, ui, node, function(g){
          s.galaxy = g;

          // overwrite system in galaxy.solar_systems
          for(var sys = 0; sys < g.solar_systems.length; sys++){
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
        // store galaxy in registry
        Entities().set(g.id, g);

        // run callbacks
        for(var cb = 0; cb < $galaxy_callbacks[g.id].length; cb++)
          $galaxy_callbacks[g.id][cb].apply(g, [g]);
        $galaxy_callbacks[g.id] = []

        // swap systems in
        // right now we only set those retrieved from the server
        for(var sys = 0; sys < g.solar_systems.length; sys++){
          var rsys = Entities().get(g.solar_systems[sys].id)
          if(rsys && rsys != -1) g.solar_systems[sys] = rsys;
        }

        // wire up solar system events
        handle_events(ui, node, g.solar_systems);

        // show in the locations container
        if(ui.canvas_container){
          ui.canvas_container.locations_list.
             list.add_item({ item : g,
                             id   : "locations_container-" + g.id,
                             text : 'Galaxy: ' + g.name });
          ui.canvas_container.locations_list.show();
        }
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
  // TODO conditionalize what is called based on attributes
  // defined in ui object
  for(var component in ui){
    if(component === "nav_container")
      wire_up_nav(ui, node);
    else if(component === "audio_player")
      wire_up_audio_player(ui, node);
    else if(component == "status_indicator")
      wire_up_status(ui, node);
    else if(component == "canvas_container")
      wire_up_canvas(ui, node);
    else if(component == "account_info")
      wire_up_account_info(ui, node);
  }
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
       var user_id             = ui.dialog.subdiv('#register_username').attr('value');
       var user_password       = ui.dialog.subdiv('#register_password').attr('value');
       var user_email          = ui.dialog.subdiv('#register_email').attr('value');
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
       ui.canvas_container.hide();
       ui.dialog.hide();

       // clean up canvas (TODO possibly move into its own method)
       ui.canvas_container.canvas.scene.clear_entities();
       ui.canvas_container.canvas.scene.skybox.shide();
       ui.canvas_container.canvas.scene.axis.shide();
       ui.canvas_container.canvas.scene.grid.shide();
       ui.canvas_container.canvas.scene.camera.reset();

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

////////////////////////////////////////// audio player

/* Internal helper to wire up audio player
 */
var wire_up_audio_player = function(ui, node){
  // TODO dynamic playlist
  var audio_path =
    "http://" + $omega_config["host"]    +
                $omega_config["prefix"]  + "/audio";
  ui.audio_player.path = audio_path;

  ui.audio_player.playlist =
    new jPlayerPlaylist({
          jPlayer: "#jquery_jplayer_1",
          cssSelectorAncestor: "#jplayer_container"},
          [{ title: "track1", oga: audio_path + "/simple2.ogg" },
           { title: "track2", oga: audio_path + "/simple4.ogg" }],
          {supplied: "oga", loop: "true"});

  ui.effects_player =
    new EffectsPlayer({path: audio_path + "/effects/"});
};

////////////////////////////////////////// entities lists

/* Internal helper to wire up entities lists
 */
var wire_up_entities_lists = function(ui, node){
  // set scene when location is clicked
  ui.canvas_container.locations_list.list.on('click_item', function(c, i, e){
    set_scene(ui, node, i.item);
  });

  // when entity is clicked: set scene, focus on entity, call clicked handler
  ui.canvas_container.entities_list.list.clear_callbacks('click_item');
  ui.canvas_container.entities_list.list.on('click_item', function(c, i, e){
    set_scene(ui, node, i.item.solar_system, i.item.location);

    // XXX keep this in sync w/ operations in scene.clicked in ui.js
    //     or abstract this functionality into seperate method (where to place?)
    i.item.clicked_in(ui.canvas_container.canvas.scene)
    i.item.raise_event('click', ui.canvas_container.canvas.scene)
  });

  // popup dialog w/ missions info when missions button is clicked
  ui.canvas_container.missions_button.on('click', function(e){
    // get latest mission data from server
    Mission.all(function(missions){
      // store missions in the registry
      for(var m = 0; m < missions.length; m++)
        Entities().set(missions[m].id, missions[m]);

      show_missions(missions, ui);
    })
  });

  // assign mission when assign link is clicked in popup dialog
  $('.assign_mission').die();
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
var set_scene = function(ui, node, entity, location){
  // hide dialog
  ui.dialog.hide();

  // unselect selected item
  var selected = Entities().select(function(e){ return (e.id != entity.id) && e.selected; })[0]
  if(selected) ui.canvas_container.canvas.scene.unselect(selected.id);

  // remove old skybox
  ui.canvas_container.canvas.scene.remove_component(ui.canvas_container.canvas.scene.skybox.components[0]);

  // remove old entities
  ui.canvas_container.canvas.scene.clear_entities();

  // set root entity
  ui.canvas_container.canvas.scene.set(entity);

  // focus on location if specified
  if(location) ui.canvas_container.canvas.scene.camera.focus(location);

  // set new skybox background
  ui.canvas_container.canvas.scene.skybox.background(entity.background);

  // add new skybox
  ui.canvas_container.canvas.scene.add_component(ui.canvas_container.canvas.scene.skybox.components[0]);

  // track planet movement
  // TODO remove callbacks of planets in old system
  if(entity.json_class == "Cosmos::Entities::SolarSystem"){
    for(var p = 0; p < entity.planets.length; p++){
      var planet = entity.planets[p];
      Events.track_movement(planet.location.id, $omega_config.planet_movement);
      // FIXME should only be on_movement for planets
      var events = ['motel::on_movement',
                    'motel::on_rotation',
                    'motel::location_stopped']
      planet.location.clear_callbacks(events);
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
    for(var m = 0; m < unassigned.length; m++)
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
  wire_up_entities_lists(ui, node);

  // wire up canvas and related components to page
  ui.canvas_container.canvas.wire_up();
  ui.canvas_container.canvas.scene.camera.wire_up();
  ui.canvas_container.canvas.scene.axis.cwire_up();
  ui.canvas_container.canvas.scene.grid.cwire_up();
  ui.canvas_container.entity_container.wire_up();

  // capture window resize and resize canvas
  $(window).resize(function(e){
    if(e.target != window) return;
    var c = ui.canvas_container.canvas;
    c.set_size(($(document).width()  - c.component().offset().left - 50),
               ($(document).height() - c.component().offset().top  - 50));
  });

  // refresh scene whenever texture is loaded
  UIResources().on('texture_loaded', function(t){ ui.canvas_container.canvas.scene.animate(); })

  // when setting scene to solar system, get all entities under it
  ui.canvas_container.canvas.scene.on('set', function(scene, entity){
    // remove event callbacks of entities in old system not beloning to user
    var old_entities =
      Entities().select(function(e){
        return (e.json_class == 'Manufactured::Ship' ||
                e.json_class == 'Manufactured::Station') &&
               (entity.id != e.system_id) &&
                e.user_id != Session.current_session.user_id;
      })

    for(var e = 0; e < old_entities.length; e++){
      var oentity = old_entities[e];
      Events.stop_track_movement(oentity.location.id);
      Events.stop_track_manufactured(oentity.id);
    }

    // refresh entities under the system
    if(entity.json_class == "Cosmos::Entities::SolarSystem")
      SolarSystem.entities_under(entity.id,
                                 function(e){
                                   process_entities(ui, node, e);
                                 });

    // reset the camera
    ui.canvas_container.canvas.scene.camera.reset();
  });

  // start the particle subsystem
  ui.canvas_container.canvas.scene.particle_timer.play();
}

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

