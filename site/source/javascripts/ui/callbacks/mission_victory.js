/* Omega JS Mission Victory Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.mission_victory = function(event, evnt_args){
  var mission = evnt_args[1];
  alert('Mission victory ' + mission.id);
};
