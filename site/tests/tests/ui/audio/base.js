pavlov.specify("Omega.BaseAudioEffect", function(){
describe("Omega.BaseAudioEffect", function(){
  describe("#dom", function(){
    it("returns audio.src page element");
  });

  describe("#loop_dom", function(){
    it("returns audio.src_loop page element");
  });

  describe("#set_volume", function(){
    it('set page element volume');
    it('set dom page element volume');
  });

  describe("#should_loop", function(){
    describe("audio.loop is true", function(){
      it("returns true");
    });
    describe("audio.loop is false", function(){
      it("returns false");
    });
  });

  describe("#_setup_loop", function(){
    describe("already setup loop", function(){
      it("does nothing / just returns");
    });

    it("listens for dom element time update events");
    it("listens for loop dom element time update events");

    describe("dom element play time is within overlap of end", function(){
      it("plays loop element");
    });

    describe("loop dom element play time is within overlap of end", function(){
      it("plays dom element");
    });
  });

  describe("#_play_element", function(){
    it("sets element time to 0");
    it("plays element");
  });

  describe("play", function(){
    describe("target specified", function(){
      it("sets target");
    });

    describe("should_loop returns true", function(){
      it("sets up audio loop");
    });

    it("plays dom element");
  });

  describe("#pause", function(){
    it("pauses dom element");
    it("pauses loop element");
  });

  describe("#set", function(){
    describe("target is a string", function(){
      it("sets target from this[target]");
    });
    it("sets current audio target");
  });
});});
