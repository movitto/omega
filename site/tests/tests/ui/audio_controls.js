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
    //  it("sets mute background", function(){)
    //});

    //describe("disabled is false", function(){ /// NIY
    //  it("sets unmute background")
    //});
  });

  //describe("#audio", function(){
    //it("returns the page element of the current track") // NIY
  //})

  describe("#set", function(){
    it("sets current track", function(){
      var page = {config : { audio : {'foo' : 'bar'}}}
      var ac = new Omega.UI.AudioControls({page : page});
      ac.set('foo');
      assert(ac.current).equals('bar');
    });
  });

  describe("#play", function(){
    var ac, audio;
    before(function(){
      ac = new Omega.UI.AudioControls();
      audio = {play : sinon.spy()};
      sinon.stub(ac, 'audio').returns(audio);
    });

    describe("player is disabled", function(){

      it("does not play audio", function(){
        ac.disabled = true;
        ac.play();
        sinon.assert.notCalled(audio.play);
      });
    });

    describe("track id specified", function(){
      it("sets current track", function(){
        var set = sinon.stub(ac, 'set');
        ac.disabled = false;
        ac.play('foo');
        sinon.assert.calledWith(set, 'foo');
      })
    });

    describe("player is not disabled", function(){
      it("plays audio", function(){
        ac.disabled = false;
        ac.play();
        sinon.assert.called(audio.play);
      });
    });
  });

  describe("#stop", function(){
    it("stops current track", function(){
      var audio = {pause : sinon.stub()};
      ac = new Omega.UI.AudioControls();
      sinon.stub(ac, 'audio').returns(audio);
      ac.stop();
      sinon.assert.called(audio.pause);
    });
  });
});});
