pavlov.specify("Omega", function(){
describe("Omega", function(){
  describe("#convert_entities", function(){
    it("converts each entity", function(){
      var entities = [{json_class: 'Cosmos::Entities::Star',   id: 'star1'},
                      {json_class: 'Cosmos::Entities::Planet', id: 'pl1'}];
      var new_entities = Omega.convert_entities(entities);
      assert(new_entities.length).equals(2);
      assert(new_entities[0]).isOfType(Omega.Star);
      assert(new_entities[0].id).equals('star1');
      assert(new_entities[1]).isOfType(Omega.Planet);
      assert(new_entities[1].id).equals('pl1');
    });
  });

  describe("#convert_entity", function(){
    it("returns js instance of class corresponding to entity", function(){
      var ship = {json_class : 'Manufactured::Ship', id: 'ship1'};
      var converted = Omega.convert_entity(ship);
      assert(converted).isOfType(Omega.Ship);
      assert(converted.id).equals('ship1');
    });

    describe("json entity passed in", function(){
      it("returns js instances converted from json data", function(){
        var json = {json_class : 'Motel::Location', data : {x : 10, y : 10, z: -42}};
        var converted = Omega.convert_entity(json);
        assert(converted).isOfType(Omega.Location);
        assert(converted.x).equals(10);
        assert(converted.y).equals(10);
        assert(converted.z).equals(-42);
      });
    });

    describe("js entity passed in", function(){
      it("returns the entity", function(){
        var ship = new Omega.Ship({id : 'ship1'});
        var converted = Omega.convert_entity(ship);
        assert(ship).isSameAs(ship);
      });
    });
  });

  //describe("#set_rotation", function(){
  //  it("rotates orientation by matrix");
  //  it("rotates orientation by euler-angles");
  //});

  //describe("#rotate_position", function(){
  //  it("rotates position by matrix");
  //});

  describe("#temp_translate", function(){
    var component, translation;

    before(function(){
      component = {position : new THREE.Vector3(0, 0, 0)};
      translation = {x : 10, y : -20, z : -30};
    });

    it("translates component position and invokes callback", function(){
      var cb = sinon.spy(function(component){
        assert(component.position.toArray()).isSameAs([-10, 20, 30]);
      });
      Omega.temp_translate(component, translation, cb);
      sinon.assert.called(cb)
    });

    it("resets component position", function(){
      var cb = function(){};
      Omega.temp_translate(component, translation, cb);
      assert(component.position.toArray()).isSameAs([0,0,0]);
    });
  });
});}); // Omega
