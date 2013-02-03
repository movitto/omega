/* registration confirmation page
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/vendor/purl.js');
require('javascripts/omega/client.js');

function callback_confirmed_registration(res, error){
  // XXX ugly
  // FIXME parameterize host
  alert("Done... redirecting");
  window.location = 'http://localhost/womega';
};

function confirm_registration(code){
  $omega_node.web_request('users::confirm_register', code, callback_confirmed_registration);
};

$(document).ready(function(){ 
  $omega_node = new OmegaClient();

  // dependendency pulled in via site layout
  $omega_navigation = new OmegaNavigationContainer();

  var rc = $.url(window.location);
  rc = rc.param('rc');
  confirm_registration(rc);
});
