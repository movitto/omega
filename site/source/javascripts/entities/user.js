/* Omega Javascript User
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega User
 */
function User(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Users::User';

  /* Return bool indicating if the current user
   * is the anonymous user
   */
  this.is_anon = function(){
    return this.id == $omega_config['anon_user'];
  }
}

User.anon_user =
  new User({ id : $omega_config.anon_user,
             password : $omega_config.anon_pass });
