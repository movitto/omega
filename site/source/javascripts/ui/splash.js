/* Omega JS Splash Screen Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.SplashScreen = function(parameters){
  /// need handle to page the splash screen is on to
  /// - lookup status
  this.page = null;

  this.div_id = '#splash_dialog';

  $.extend(this, parameters);
};

Omega.UI.SplashScreen.prototype = {
  enabled : false,

  cycle_interval : 10, /// seconds

  wire_up : function(){
    var _this = this;
    this.dialog().on('dialogclose',
      function(evnt){
        _this.show_notices();
      });
  },

  clear_notices : function(){
    var notices = this.read_notices();
    for(var n = 0; n < notices.length; n++)
      $.localStorage.remove('omega.notices.' + notices[n]);
  },

  read_notices : function(){
    var notices = Omega.UI.SplashContent.notices;
    var storage_keys = $.localStorage.keys();
    var read = [];
    for(var k = 0; k < storage_keys.length; k++){
      var skey = storage_keys[k];
      if(skey.substr(0, 14) == 'omega.notices.'){
        var notice_id = skey.substr(14, skey.length-13);
        read.push(notice_id);
      }
    }

    return read;
  },

  unread_notices : function(){
    var notices = Omega.UI.SplashContent.notices;
    var read    = this.read_notices();
    var unread  = [];
    for(var notice_id in notices)
      if(read.indexOf(notice_id) == -1)
        unread.push(notice_id);
    return unread;
  },

  show_notice : function(notice_id){
    /// TODO set this when notice is manually closed by user
    $.localStorage.set('omega.notices.' + notice_id, true)

    var notice = Omega.UI.SplashContent.notices[notice_id];
    this.title = notice.title;
    $('#splash_content').html(notice.text);
    this.show();
  },

  show_notices : function(){
    var unread = this.unread_notices();
    if(unread.length == 0){
      this.showing_notices = false;
      return;
    }

    this.showing_notices = true;
    var notice = unread[0];
    this.show_notice(notice);
  },

  show_tip : function(tip_id){
    var tip = Omega.UI.SplashContent.tips[tip_id];
    this.title = tip.title;
    $('#splash_content').html(tip.text);
    this.show();
  },

  show_screenshot : function(screenshot_id){
    var screenshot = Omega.UI.SplashContent.screenshots[screenshot_id];
    this.title = screenshot.title;

    /// TODO set screenshot width / height
    var splash_content = $('#splash_content');
    var img = $('<img/>', {src : screenshot.img} )
    splash_content.html('');
    splash_content.append(img);
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
    /// TODO fade out old / fade in new
    if(this.ci % this.cycle_interval == 0){
      if(!this.showing_notices) this.show_random();
      this.ci  = 1;
    }else{
      this.ci += 1;
    }

    /// TODO min amount of time any 'tip' or 'screenshot'
    /// will be displayed for even if stop is invoked here
    /// (so first tip / screenshot doesn't appear & fade quickly
    ///  if resources are loaded quickly)
    if(this._should_stop()) this.stop();
  },

  /// stop cycle when no longer loading resources
  _should_stop : function(){
    return !this.page.status_indicator.has_state('loading_resource');
  },

  start : function(){
    this.show_notices();

    /// if splash is not enabled, still show
    /// notices but do not show tips / screenshots
    if(!this.enabled){
      this.stop();
      return;
    }

    this.ci    =    0;
    var _this  = this;
    this.cycle = $.timer(function(){ _this._run_cycle(); }, 1000, true);
  },

  stop : function(){
    if(this.cycle) this.cycle.stop();
    if(!this.showing_notices) this.hide();
  }
};

$.extend(Omega.UI.SplashScreen.prototype,
         new Omega.UI.Dialog());

/// XXX we statically define content here, should
/// figure out a better location to load it from
Omega.UI.SplashContent = {
  notices : {
    performance :
      {title : "Regarding Performance",
       text  : "Omega comes with <b>~30MB</b> of content which " +
               "your web browser is currently downloading.<br/><br/>" +
               "The '<b>Loading Resources</b>' icon in the lower left " +
               "will dissapear when all content is loaded"},
    welcome :
      {title : "Welcome to the Omegaverse",
       text  : "<h3>New User? Need Help? See the <a style='color: blue;'"+
               " href='https://github.com/movitto/omega/wiki/Using-the-Web-UI'>Tutorial</a>!</h3>"}
  },

  tips : [
    {title : "tips1 title",
     text  : "tips1 text"},
    {title : "tips2 title",
     text  : "tips2 text"}
  ],

  screenshots : [
    {title : "screenshot1 title",
     img   : "http://url/for/screenshot1.png"},
    {title : "screenshot2 title",
     img   : "http://url/for/screenshot2.png"}
  ]

/// FIXME content
};
