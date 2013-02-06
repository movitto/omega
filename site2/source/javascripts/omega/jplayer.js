/* Omega JPlayer Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/vendor/jquery.jplayer.min.js');
require('javascripts/vendor/jquery.jplayer.playlist.min.js');
require('javascripts/omega/config.js');

/////////////////////////////////////// initialization 

// TODO dynamic playlist
$(document).ready(function(){
    var playlist =
    new jPlayerPlaylist({
        jPlayer: "#jquery_jplayer_1",
        cssSelectorAncestor: "#jplayer_container"},
        [{ title: "track1", wav: "http://"+$omega_config["host"]+":4567/audio/simple2.wav" },
         { title: "track2", wav: "http://"+$omega_config["host"]+":4567/audio/simple4.wav" }],
        {swfPath: "js", supplied: "wav", loop: "true"});
   //$('.jp-play').click(function(){ console.log(playlist); playlist.play(); });
});
