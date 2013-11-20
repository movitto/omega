pavlov.specify("Omega.UI.EffectsPlayer", function(){
describe("Omega.UI.EffectsPlayer", function(){
  after(function(){
    Omega.UI.Dialog.remove();
  })

  describe('#wire_up', function(){
    it('wires up document visibility change events');
    describe("on document hidden", function(){
      it("stops effects timer");
    });

    describe("on document shown", function(){
      describe("effects timer previously playing", function(){
        it("starts effects timer");
      });
      describe("effects timer not previously playing", function(){
        it("does nothing / just returns");
      });
    });
  });

  describe("#start", function(){
    it('creates effects timer');
    it('plays effects timer');
    it('sets playing true');
  });

  describe("effect loop interation", function(){
    it("invokes #run_effects on all scene objects' omega_entity handles");
  });
});});
