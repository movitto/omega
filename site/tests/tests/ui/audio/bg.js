pavlov.specify("Omega.BackgroundAudio", function(){
describe("Omega.BackgroundAudio", function(){
  describe("initialization", function(){
    it("initializes effects");
    it("shuffles effects");
    it("sets this.current to 0");
  });

  describe("#_shuffle_effects", function(){
    it("randomizes effects")
  });

  describe("#init_effects", function(){
    it("initializes this.num based audio effects");
    it("adds listener for ended event")
    describe("audio effect ended", function(){
      it("invokes this._effect_ended");
    });
  });

  describe("#current_effect", function(){
    it("returns currently seleted effect")
  });

  describe("#_effect_ended", function(){
    describe("this.played > this.times", function(){
      it("starts effect fade");
    });

    describe("this.played <= this.times", function(){
      it("does nothing / just returns");
    });
  });

  describe("#_start_fade", function(){
    it("starts fade timer");
    describe("fade timer", function(){
      it("reduces volume of current element by 0.1");
      describe("after 10 iterations", function(){
        it("restores audio volume")
        it("pauses current audio effect")
        it("invokes this.play")
        it("stops fade timer")
      });
    })
  });

  describe("#set_volume", function(){
    it("sets volume on all audio effects");
  });

  describe("#play", function(){
    it("increments current effect counter")
    describe("current effect counter exceeds total", function(){
      it("sets current effect count")
    });

    it("sets this.played = 1");
    it("generates a random number of times to play from configured max")
    it("plays current effect")
  });

  describe("#pause", function(){
    it("pauses all the effects");
  });
});});
