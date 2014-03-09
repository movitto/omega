pavlov.specify("Omega.ShipTrajectory", function(){
describe("Omega.ShipTrajectory", function(){
  describe("#update", function(){
    var loc, trajectory;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      trajectory = new Omega.ShipTrajectory();
      trajectory.omega_entity = {location: loc};
    });

    it("sets position of primary trajectory", function(){
      trajectory.set_direction('primary');
      trajectory.update();
      assert(trajectory.mesh.position.x).equals(loc.x);
      assert(trajectory.mesh.position.y).equals(loc.y);
      assert(trajectory.mesh.position.z).equals(loc.z);
    });

    it("sets position of secondary trajectory", function(){
      trajectory.set_direction('secondary');
      trajectory.update();
      assert(trajectory.mesh.position.x).equals(loc.x);
      assert(trajectory.mesh.position.y).equals(loc.y);
      assert(trajectory.mesh.position.z).equals(loc.z);
    });

    //it("sets trajectory vertices to be aligned w/ orientation"); /// NIY

    it("marks trajectory geometry as needing update", function(){
      trajectory.update();
      assert(trajectory.mesh.geometry.verticesNeedUpdate).equals(true);
    });
  });
});}); // Omega.ShipTrajectory
