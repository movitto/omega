function errors_to_console(error_msg){
  console.log(error_msg);
}

function set_root_entity(entity_id){
console.log(entity_id);
  var entity = $tracker.entities[entity_id];
  hide_entity_container();
  $('#omega_canvas').css('background', 'url("/womega/images/backgrounds/' + entity.background + '.png") no-repeat');

  for(var child in entity.children){
    child = entity.children[child];
    $scene.add(child);
  }
  $scene.animate();
}

function refresh_stats(){
  var cosmos_stats    = $('#stats_cosmos ul');
  var entities_stats  = $('#stats_entities ul');
  var users_stats     = $('#stats_users ul');
  var actions_stats   = $('#stats_actions ul');
   users_stats.html('');  actions_stats.html('');
  cosmos_stats.html(''); entities_stats.html('');

  for(var entity in $tracker.entities){
    entity = $tracker.entities[entity];
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

function got_entities(entities, error){
  if(error == null){
    for(var entity in entities){
      entity = entities[entity];
      register_entity(entity);
    }
    refresh_stats();
  }
}

function refresh_cycle(args){
  omega_web_request('manufactured::get_entity', got_entities);
  omega_web_request('cosmos::get_entity', 'of_type', 'Cosmos::Galaxy', got_entities);
  omega_web_request('users::get_entity', 'of_type', 'Users::User', got_entities);
  setTimeout(refresh_cycle, 5000);
}

$(document).ready(function(){ 
  $error_handlers.push(errors_to_console);
  $validate_session_callbacks.push(refresh_cycle);
  $login_callbacks.push(refresh_cycle);

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

  $('#stats_cosmos li').live('click', function(event){ 
    var entity_id = $(event.currentTarget).attr('name');
    set_root_entity(entity_id);
    return false;
  });
});
