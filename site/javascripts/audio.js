$(document).ready(function(){
    var playlist =
    new jPlayerPlaylist({
        jPlayer: "#jquery_jplayer_1",
        cssSelectorAncestor: "#motel_jplayer_container"},
        [{ title: "track1", wav: "http://localhost/womega/audio/simple2.wav" },
         { title: "track2", wav: "http://localhost/womega/audio/simple4.wav" }],
        {swfPath: "js", supplied: "wav", loop: "true"});
   //$('.jp-play').click(function(){ console.log(playlist); playlist.play(); });
});
