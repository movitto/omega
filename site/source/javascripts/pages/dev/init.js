/* Omega JS Dev Page Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/gen"

Omega.Pages.DevInitializer = {
  wire_up : function(){
    var _this = this;
    this.canvas.wire_up();
    this.effects_player.wire_up();
    this.audio_controls.wire_up();

    this.setup();
    return this;
  },

  setup : function(){
    var _this = this;
    this.canvas.init_gl().append();
    this.canvas.cam.position.set(25000, 25000, 25000);
    this.canvas.focus_on({x:0,y:0,z:0});

    Omega.Gen.init(function(){
      _this.custom_operations();
    });

    var light = new THREE.DirectionalLight(0xFFFFFF, 1.0);
    this.canvas.scene.add(light);

    var bg = Math.floor(Math.random() * Omega._num_backgrounds) + 1;
    this.canvas.skybox.set(bg, function(){_this.canvas.animate();})
    this.canvas.add(this.canvas.skybox, this.canvas.skyScene);
    this.canvas.add(this.canvas.star_dust, this.canvas.skyScene);

    this.canvas.animate();
  }
};
