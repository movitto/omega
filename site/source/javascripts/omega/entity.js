/* Omega Javascript Entities
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/three-r58"
//= require "vendor/helvetiker_font/helvetiker_regular.typeface"

/////////////////////////////////////////////////////////////////////

/* Entity registry, track all entities in the system
 *
 * Implements singleton pattern
 */
function Entities(){
  if ( Entities._singletonInstance )
    return Entities._singletonInstance;
  var _this = {};
  Entities._singletonInstance = _this;

  $.extend(_this, new Registry());

  /* Get/set node used to retrieve entities below
   */
  _this.node = function(new_node){
    if(new_node != null) _this._node = new_node;
    return _this._node;
  }

  return _this;
}

/////////////////////////////////////////////////////////////////////

/* Base Entity Class.
 *
 * Subclasses should define 'json_class' attribute
 */
function Entity(args){
  $.extend(this, new EventTracker());

  // copy all args to local attributes
  // http://api.jquery.com/jQuery.extend/
  this.update = function(args){
    for(var a in args){
      var arg = args[a];
      if($.inArray(a, this.ignore_properties) == -1)
        this[a] = arg;
    }
    this.raise_event('updated', this);
  }
  this.update(args);

  // return new copy of this
  this.clone = function(){
    return $.extend(true, {}, this);
  }

  /* Scene callbacks
   */
  this.added_to      = function(scene){}
  this.removed_from  = function(scene){}
  this.clicked_in    = function(scene){}
  this.unselected_in = function(scene){}

  /* add properties to ignore in json conversion
   */
  this.ignore_properties = ['toJSON', 'json_class', 'ignore_properties',
                            'added_to', 'removed_from', 'callbacks',
                            'clicked_in', 'unselected_in', 'update',
                            'raise_event', 'clone', 'on',
                            'clear_callbacks'];

  /* Convert entity to json respresentation
   */
  this.toJSON = function(){
    return new JRObject(this.json_class, this, this.ignore_properties).toJSON();
  };
}
