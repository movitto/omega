pavlov.specify("Omega.UI.AudioControls", function(){
describe("Omega.UI.AudioControls", function(){
  it("is disabled by default", function(){
    var ac = new Omega.UI.AudioControls();
    assert(ac.disabled).equals(true);
  });

  describe("#wire_up", function(){
    it("wires up mute button click", function(){
      assert($('#mute_audio')).doesNotHandle('click');
      var ac = new Omega.UI.AudioControls();
      ac.wire_up();
      assert($('#mute_audio')).handles('click');
    });

  });

  describe("on mute button click", function(){
    it("toggles component", function(){
      var ac = new Omega.UI.AudioControls();
      var toggle = sinon.spy(ac, 'toggle');
      ac.wire_up();
      $('#mute_audio').click();
      sinon.assert.called(toggle);
    });
  });

  describe("#toggle", function(){
    it("inverts disabled flag", function(){
      var ac = new Omega.UI.AudioControls();
      assert(ac.disabled).isTrue();
      ac.toggle();
      assert(ac.disabled).isFalse();
    });

    //describe("disabled is true", function(){ /// NIY
    //  it("sets volume to 0")
    //  it("sets mute background", function(){)
    //});

    //describe("disabled is false", function(){ /// NIY
    //  it("sets volume to 1")
    //  it("sets unmute background")
    //});
  });

  //describe("#set_volume", function(){
    //it("sets local volume");
    //it("sets volume of currently playing elements") /// NIY
  //});

  describe("#play", function(){
    var ac, audio;

    before(function(){
      ac = new Omega.UI.AudioControls();
      audio = {play : sinon.stub(), set_volume : sinon.stub()};
    });

    it("adds track to playing list", function(){
      ac.disabled = false;
      ac.play(audio);
      assert(ac.playing).includes(audio);
    })

    it("plays track", function(){
      ac.disabled = false;
      ac.play(audio);
      sinon.assert.called(audio.play);
    });

    it("specifies track ended callback", function(){
      ac.disabled = false;
      ac.play(audio);
      sinon.assert.calledWith(audio.play, sinon.match.func);
    });

    describe("track ended", function(){
      it("stops playing track", function(){
        ac.disabled = false;
        ac.play(audio);
        sinon.stub(ac, 'stop')
        audio.play.omega_callback()();
        sinon.assert.calledWith(ac.stop, audio);
      })
    })

    it("sets track volume to local volume", function(){
      ac.volume = 0.23;
      ac.play(audio);
      sinon.assert.called(audio.set_volume, ac.volume);
    });
  });

  describe("#stop", function(){
    var ac
    
    before(function(){
      ac = new Omega.UI.AudioControls();
    });

    it("removes track from playing list", function(){
      var audio = {pause : sinon.stub()};
      ac.playing = [audio];
      ac.stop(audio);
      assert(ac.playing).doesNotInclude(audio);
    });

    it("stops the specified track", function(){
      var audio = {pause : sinon.stub()};
      ac.stop(audio);
      sinon.assert.called(audio.pause);
    });

    it("stops the specified tracks", function(){
      var audio1 = {pause : sinon.stub()};
      var audio2 = {pause : sinon.stub()};
      ac.stop([audio1, audio2]);
      sinon.assert.called(audio1.pause);
      sinon.assert.called(audio2.pause);
    });
  });
});});
