/* Omega Page EventHandler Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.EventHandler = {
  /// Helper to register handlers for all supported events
  _handle_events : function(){
    var events = Omega.CallbackHandler.all_events();
    for(var e = 0; e < events.length; e++)
      this.callback_handler.track(events[e]);
  }
};
