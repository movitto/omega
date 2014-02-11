/* Omega JS Splash Screen Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.SplashScreen = function(parameters){
  /// need handle to page the splash screen is on to
  /// - lookup status
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.SplashScreen.prototype = {
  cycle_interval : 10,

  wire_up : function(){
  },

  read_notices : function(){
    var notices = Omega.UI.SplashContent.notices;
    var storage_keys = $.localStorage.keys();
    var read = [];
    for(var k = 0; k < storage_keys.length; k++){
      var skey = storage_keys[k];
      if(skey.substr(0, 14) == 'omega.notices.'){
        var notice = notices[skey.substr(14, skey.length-13)];
        read.push(notice);
      }
    }

    return read;
  },

  unread_notices : function(){
    var notices = Omega.UI.SplashContent.notices;
    var read    = this.read_notices();
    var unread  = [];
    for(var n = 0; n < notices.length; n++)
      if(read.indexOf(notices[n]) == -1)
        unread.push(notices[n]);
    return unread;
  },

  show_notice : function(notice_id){
  },

  show_notices : function(){
    /// TODO show notice unless already shown,
    /// when user closes a notice, store that they already viewed notice_id in localstorage
  },

  show_tip : function(tip_id){
/// FIXME unless showing notices
    var tip = Omega.UI.SplashContent.tips[tip_id];
    this.title = tip.title;
    this.text  = tip.text;
    this.show();
  },

  show_screenshot : function(screenshot_id){
/// FIXME unless showing notices
    var screenshot = Omega.UI.SplashContent.tips[screenshot_id];
    this.title = screenshot.title;
/// FIXME populate content w/ img
    this.show();
  },

  show_random : function(){
    var tips        = Omega.UI.SplashContent.tips;
    var screenshots = Omega.UI.SplashContent.screenshots;

    var rand = Math.floor(Math.random() * 2) == 0;
    if(rand)
      this.show_tip(Math.floor(Math.random() * tips.length));
    else
      this.show_screenshot(Math.floor(Math.random() * screenshots.length));
  },

  _run_cycle : function(){
    if(this.ci == this.cycle_interval){
      this.show_random();
      this.ci  = 0;
    }else{
      this.ci += 1;
    }

    /// stop cycle when no longer loading resources
    if(!this.page.status_indicator.has_state('resource_loading'))
      this.stop();
  },

  start : function(){
    this.show_notices();

    this.ci    =    0;
    var _this  = this;
    this.cycle = $.timer(function(){ _this._run_cycle(); }, 1000, true);
  },

  stop : function(){
    this.cycle.stop();
/// FIXME unless showing notices
    this.hide();
  }
};

$.extend(Omega.UI.SplashScreen.prototype,
         new Omega.UI.Dialog());

/// XXX we statically define content here, should
/// figure out a better location to load it from
Omega.UI.SplashContent = {
  notices : {
    performance : {title : "", text : ""}
  },

  tips : {
    navigation  : {title : "", text : ""}
  },

  screenshots : [
    {title : "", img : ""}
  ]

  /// ...
};
