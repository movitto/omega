/* Omega JS Contstriction Mechanisms
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Constraint = {
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

  _get_scale : function(target){
    var targetS = target.slice(0);
    var field   = targetS[targetS.length-1];
    var scale   = field + 'Scale';
    targetS[targetS.length-1] = scale;
    return this._get(targetS)
  },

  _coin_flip : function(){
    return (Math.floor(Math.random() * 2) == 0);
  },

  _randomize : function(base, deviation){
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

  _scale : function(adjusted, base, deviation, scale){
    var min = scale.min;
    var max = scale.max;

    if(typeof(base) === "object"){
      var minbx = base.x - deviation.x;
      var minby = base.y - deviation.y;
      var minbz = base.z - deviation.z;
      var percentx = (adjusted.x - minbx) / (2*deviation.x);
      var percenty = (adjusted.y - minby) / (2*deviation.y);
      var percentz = (adjusted.z - minbz) / (2*deviation.z);
      return {x: min.x + percentx * (max.x - min.x),
              y: min.y + percenty * (max.y - min.y),
              z: min.z + percentz * (max.z - min.z)};
    }

    var minb = base - deviation;
    var percent = (adjusted - minb) / (2*deviation);

    return min + percent * (max - min);
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
    var scale     = this._get_scale(target);
    var adjusted  = base;

    if(deviation)
      adjusted = this._randomize(base, deviation);
    if(deviation && scale)
      adjusted = this._scale(adjusted, base, deviation, scale);

    return adjusted;
  }
};
