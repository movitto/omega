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
    //it("sets volume of currently playing element") /// NIY
  //});

  describe("#play", function(){
    var ac, audio;

    before(function(){
      ac = new Omega.UI.AudioControls();
      audio = {play : sinon.stub(), set_volume : sinon.stub()};
    });

    describe("track specified", function(){
      it("sets current track", function(){
        ac.disabled = false;
        ac.play(audio);
        assert(ac.current).equals(audio);
      })

      it("plays track", function(){
        ac.disabled = false;
        ac.play(audio);
        sinon.assert.called(audio.play);
      });
    });

    it("plays current track", function(){
      ac.disabled = false;
      ac.play(audio);
      sinon.assert.called(audio.play);
      audio.play.reset();
      ac.play();
      sinon.assert.called(audio.play);
    });
  });

  describe("#stop", function(){
    it("stops current track", function(){
      var audio = {pause : sinon.stub()};
      ac = new Omega.UI.AudioControls();
      ac.current = audio;
      ac.stop();
      sinon.assert.called(audio.pause);
    });
  });
});});
