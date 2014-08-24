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

    it("sets orientation of primary trajectory", function(){
      trajectory.set_direction('primary');
      trajectory.update();
      assert(trajectory.mesh.geometry.vertices[0].x).equals(0);
      assert(trajectory.mesh.geometry.vertices[0].y).equals(0);
      assert(trajectory.mesh.geometry.vertices[0].z).equals(0);
      assert(trajectory.mesh.geometry.vertices[1].x).equals(0);
      assert(trajectory.mesh.geometry.vertices[1].y).equals(0);
      assert(trajectory.mesh.geometry.vertices[1].z).equals(100);
    });

    it("sets position of secondary trajectory", function(){
      trajectory.set_direction('secondary');
      trajectory.update();
      assert(trajectory.mesh.geometry.vertices[0].x).equals(0);
      assert(trajectory.mesh.geometry.vertices[0].y).equals(0);
      assert(trajectory.mesh.geometry.vertices[0].z).equals(0);
      assert(trajectory.mesh.geometry.vertices[1].x).equals(0);
      assert(trajectory.mesh.geometry.vertices[1].y).equals(50);
      assert(trajectory.mesh.geometry.vertices[1].z).equals(0);
    });

    //it("sets trajectory vertices to be aligned w/ orientation"); /// NIY

    it("marks trajectory geometry as needing update", function(){
      trajectory.update();
      assert(trajectory.mesh.geometry.verticesNeedUpdate).equals(true);
    });
  });
});}); // Omega.ShipTrajectory
