/* Omega Solar System Audio Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemAudioEffects = function(args){
  if(!args) args = {};
  var config = args['config'];

  this.hover = config.audio['system_hover'];
  this.click = config.audio['system_click'];
};

Omega.SolarSystemAudioEffects.prototype = {
  hover_dom : function(){
    return $('#' + this.hover.src)[0];
  },

  click_dom : function(){
    return $('#' + this.click.src)[0];
  },

  play_hover : function(){
    this.hover_dom().play();
  },

  play_click : function(){
    this.click_dom().play();
  },

  play : function(target){
    if(target == 'hover')
      this.play_hover();
    else if(target == 'click')
      this.play_click();
  },

  pause : function(){
    this.hover_dom().currentTime = 0;
    this.hover_dom().pause();

    //this.click_dom().currentTime = 0;
    //this.click_dom().pause();
  }
};
