/* Omega JS Contstriction Mechanisms
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Constraint = {
  url : function(config){
    return "http://" + config.http_host + config.url_prefix + config.constraints;
  },

  load : function(url, cb){
    if(url){
      var _this = this;

      this.url = url;
      $.get(this.url, function(data){
        _this._json = data;
        if(cb) cb();
      });
    }
    return this.url;
  },

  _get : function(target){
    var current = this._json;
    if(!current)
      throw "Entity constraints are null, call Omega.Constraint.load(url, cb)";

    for(var t = 0; t < target.length; t++){
      current = current[target[t]];
      if(typeof(current) === "undefined") return null;
    }

    return current;
  },

  _get_deviation : function(target){
    var targetD   = target.slice(0);
    var field     = targetD[targetD.length-1];
    var deviation = field + 'Deviation';
    targetD[targetD.length-1] = deviation;
    return this._get(targetD)
  },

  _coin_flip : function(){
    return (Math.floor(Math.random() * 2) == 0);
  },

  _randomize : function(base, deviation){
    if($.isArray(base)) return base[Math.floor(Math.random()*base.length)];
    if(!deviation) return base;

    if(typeof(base) === "object"){
      var nx = this._coin_flip() ? 1 : -1;
      var ny = this._coin_flip() ? 1 : -1;
      var nz = this._coin_flip() ? 1 : -1;
      return {x: base.x + Math.random() * deviation.x * nx,
              y: base.y + Math.random() * deviation.y * ny,
              z: base.z + Math.random() * deviation.z * nz};
    }

    var n = this._coin_flip() ? 1 : -1;
    return base + Math.random() * deviation * n;
  },

  rand_invert : function(value){
    if(typeof(value) === "object"){
      var nx = this._coin_flip() ? 1 : -1;
      var ny = this._coin_flip() ? 1 : -1;
      var nz = this._coin_flip() ? 1 : -1;
      return {x: nx * value.x, y: ny * value.y, z: nz * value.z};
    }

    var n = this._coin_flip() ? 1 : -1;
    return n * value;
  },

  gen : function(){
    var target    = Array.prototype.slice.call(arguments);
    var base      = this._get(target);
    var deviation = this._get_deviation(target);
    return this._randomize(base, deviation);
  },

  _max : function(target){
    var base      = this._get(target);
    var deviation = this._get_deviation(target);
    if(!deviation) return base;

    if(typeof(base) === "object"){
      return {'x' : base['x'] + deviation['x'],
              'y' : base['y'] + deviation['y'],
              'z' : base['z'] + deviation['z']};
    }

    return base + deviation;
  },

  _min : function(target){
    var base      = this._get(target);
    var deviation = this._get_deviation(target);
    if(!deviation) return base;

    if(typeof(base) === "object"){
      return {'x' : base['x'] - deviation['x'],
              'y' : base['y'] - deviation['y'],
              'z' : base['z'] - deviation['z']};
    }

    return base - deviation;
  },

  valid : function(){
    var args      = Array.prototype.slice.call(arguments);
    var current   = args.shift();
    var base      = this._get(args);
    var deviation = this._get_deviation(args);

    if($.isArray(base)) return base.indexOf(current) != -1;
    if(!deviation) return current == base;

    var max = this._max(args);
    var min = this._min(args);

    if(typeof(base) === "object"){
      return current['x'] <= max['x'] && current['x'] >= min['x'] &&
             current['y'] <= max['y'] && current['y'] >= min['y'] &&
             current['z'] <= max['z'] && current['z'] >= min['z'];
    }

    return current <= max && current >= min;
  }
};
