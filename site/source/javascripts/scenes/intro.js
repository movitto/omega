/* Omega Intro Scene
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "scenes/intro/audio"
//= require "scenes/intro/title"

Omega.Scenes.Intro = function(config){
  this.audio = new Omega.Scenes.IntroAudio(config);
  this.title = new Omega.Scenes.IntroTitle("the omegaverse");
};

Omega.Scenes.Intro.prototype = {
  id : 'intro',

  run : function(page){
    var _this = this;

    page.canvas.cam.position.set(0, 0, 500);
    page.canvas.focus_on({x:0,y:0,z:0});
    page.canvas.scene.add(new THREE.DirectionalLight(0xFFFFFF, 1.0));

    page.audio_controls.play(this.audio);

    /// timer to zoom camera into origin
    $.timer(function(){
      page.canvas.cam.position.z -= 1;
    }, 50, true);

    /// timer to show title
    $.timer(function(){
      page.audio_controls.play(_this.audio);
      page.canvas.add(_this.title);
      this.stop();
    }, 3000, true);

    /// timer to remove title near end
    $.timer(function(){
      /// TODO should slowly fade out
      page.canvas.remove(_this.title);
      this.stop();
    }, 13000, true);
  },
};
