/* registration confirmation page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega"
//= require "vendor/purl"

function callback_confirmed_registration(res){
  // XXX ugly
  alert("Done... redirecting");
  window.location = 'http://'+$omega_config['host']+$omega_config['prefix']
};

function confirm_registration(node, code){
  node.web_request('users::confirm_register', code,
                   callback_confirmed_registration);
};

$(document).ready(function(){ 
  // initialize top level components
  var ui   = UI();
  var node = Node();

  var rc = $.url(window.location);
  rc = rc.param('rc');
  confirm_registration(node, rc);
});
