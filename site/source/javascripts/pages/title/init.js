/* Omega JS Title Page Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require_tree "../../scenes"

Omega.Pages.TitleInitializer = {
  init_title : function(){
    var intro = {id    : 'intro',
                 text  : 'Intro',
                 scene : new Omega.Scenes.Intro()};
    var tech1 = {id    : 'tech1',
                 text  : 'tech demo1',
                 scene : new Omega.Scenes.Tech1()};
    var tech2 = {id    : 'tech2',
                 text  : 'tech demo2',
                 scene : new Omega.Scenes.Tech2()};
    var previewer = {id    : 'previewer',
                     text  : 'Entity Previewer',
                     scene : new Omega.Scenes.Previewer()};

    this.cutscenes = [intro, tech1, tech2, previewer];
  },

  cutscene : function(id){
    for(var s = 0; s < this.cutscenes.length; s++){
      var cutscene = this.cutscenes[s];
      if(cutscene.id == id)
        return cutscene;
    }

    return null;
  },

  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
    this.audio_controls.wire_up();

    /// enable audio by default
    this.audio_controls.toggle();

    var _this = this;
    this.cutscene_control().on('click', function(){
      _this.cutscene_menu().toggle();
    });

    this.cutscene_menu().on('click', '.cutscene_menu_item',
      function(evnt){
        var cutscene = $(evnt.currentTarget).data('cutscene');
        _this.play(cutscene.scene);
      });

    this.canvas.init_gl().append();

    /// add cuscenes to menu
    for(var c = 0; c < this.cutscenes.length; c++){
      var cutscene  = this.cutscenes[c];
      var menu_item = $("<div>", {class : 'cutscene_menu_item',
                                  text  :  cutscene.text});
      menu_item.data('cutscene', cutscene);
      this.cutscene_menu().append(menu_item);
    }

    return this;
  }
};
