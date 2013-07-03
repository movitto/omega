/* Omega Javascript entity registry
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Tracks events and callbacks
 */
function EventTracker(){
  this.callbacks = {};

  /* Register callback to be invoked on the specified event
   */
  this.on = function(cb_id, cb){
    // if array is passed in, call this on each element
    if($.isArray(cb_id)){
      for(var i in cb_id)
        this.on(cb_id[i], cb);
      return;
    }

    if(!this.callbacks[cb_id]) this.callbacks[cb_id] = []
    this.callbacks[cb_id].push(cb);
  }

  /* Clear callbacks, either for the specified event or all events
   */
  this.clear_callbacks = function(evnt){
    if(evnt == null){
      this.callbacks = {};

    }else{
      // if array is passed in, call this on each element
      if($.isArray(evnt)){
        for(var i in evnt)
          this.clear_callbacks(evnt[i]);
        return;
      }
      this.callbacks[evnt] = [];

    }
  }

  /* Raise event w/ the specified args
   */
  this.raise_event = function(){
    var args = args_to_arry(arguments);

    var evnt = args.shift();
    args.unshift(this);
    if(this.callbacks[evnt])
      for(var e in this.callbacks[evnt])
        this.callbacks[evnt][e].apply(this, args);
  }

  return this;
}

/* Instantiate and return a new Registry instance
 */
function Registry(){
  // actual registry
  var entities = {};

   /* Retrieve entity specified by id, or null if not found
    */
   this.get = function(id){
     return entities[id];
   }

   /* Retrieve entity specified by id, or invoke block to
    * generate it if null (the result of the block will be
    * locally stored and returned)
    */
   this.cached = function(id, cb){
     var val = this.get(id);
     if(val == null){
       val = cb.apply(null, [id]);
       if(val != null) this.set(id, val);
     }
     return val;
   }

   /* Set value in the registry by id
    */
   this.set = function(id, entity){
     entities[id] = entity;
   }

   /* invoke callback for each element in registry, returning
    * those that match true
    */
   this.select = function(callback){
     return $.grep(obj_values(entities), callback);
   }

   /* wrapper around select, return the first element
    */
   this.find = function(callback){
     return this.select(callback)[0];
   }
}
