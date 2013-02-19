/* stats page
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/omega/client.js');
require('javascripts/omega/user.js');
require('javascripts/omega/entity.js');
require('javascripts/omega/commands.js');

// log all errors to the console
function errors_to_console(error_msg){
  console.log(error_msg);
}

// repopulate the states panels w/ latest data from the trackers
function refresh_stats(){
  var cosmos_stats    = $('#stats_cosmos ul');
  var entities_stats  = $('#stats_entities ul');
  var users_stats     = $('#stats_users ul');
  var actions_stats   = $('#stats_actions ul');
   users_stats.html('');  actions_stats.html('');
  cosmos_stats.html(''); entities_stats.html('');

  var entities = $omega_registry.entities();
  for(var entity in entities){
    var entity = entities[entity];
    if(entity.json_class == "Manufactured::Ship" ||
       entity.json_class == "Manufactured::Station"){
      entities_stats.append('<li>' + entity.id + '@' + entity.location.to_s() + '</li>');
      // TODO loop through mining / attack actions
    }else if(entity.json_class == "Cosmos::Galaxy"){
      var txt = '<li name="'+entity.id+'">' + entity.id + '<ul>';
      for(var sys in entity.solar_systems){
        sys = entity.solar_systems[sys];
        txt += '<li name="'+sys.name+'">' + sys.name + '</li>';
      }
      txt += '</ul></li>';
      cosmos_stats.append(txt);
    }else if(entity.json_class == "Users::User"){
      users_stats.append('<li>' + entity.id + '</li>');
    }
  }
}

// retrieve all entities we can, refresh the stats panels, and
// schedule this again in 5s
function refresh_cycle(args){
  OmegaQuery.all_entities(refresh_stats);
  OmegaQuery.all_galaxies(refresh_stats);
  OmegaQuery.all_users(refresh_stats);
  setTimeout(refresh_cycle, 5000);
}

// initialize the page
$(document).ready(function(){ 
  $omega_node     = new OmegaClient();
  $omega_session  = new OmegaSession();
  $omega_registry = new OmegaRegistry();
  $omega_registry.load();
  OmegaCommand.init();

  // dependency pulled in via canvas partial
  $omega_canvas_ui = new OmegaCanvasUI();

  // pulled in via renderer, used in a few modules
  $omega_scene  = new OmegaScene();

  // dependendency pulled in via site layout
  $omega_navigation = new OmegaNavigationContainer();

  $omega_node.add_error_handler(errors_to_console);
  $omega_session.on_session_validated(refresh_cycle);

  // lock stats nav to its current position
  $('#stats_nav').css({
    position: 'absolute',
    top: $('#stats_nav').position().top,
    left: $('#stats_nav').position().left
  });

  /////////////////////// entities container controls

  $('.omega_display_stats').live('mouseenter', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').show();
  });
  
  // hide entities container info
  $('.omega_display_stats').live('mouseleave', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').hide();
  });

});
