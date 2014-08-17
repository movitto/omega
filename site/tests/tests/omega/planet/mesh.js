pavlov.specify("Omega.PlanetMesh", function(){
describe("Omega.PlanetMesh", function(){
  it("has a THREE.Mesh instance", function(){
    var planet_mesh = new Omega.PlanetMesh({config: Omega.Config, type: 0});
    assert(planet_mesh.tmesh).isOfType(THREE.Mesh);
    assert(planet_mesh.tmesh.geometry).isOfType(THREE.SphereGeometry);
    assert(planet_mesh.tmesh.material).isOfType(THREE.MeshLambertMaterial);
  });
});});

pavlov.specify("Omega.PlanetMaterial", function(){
describe("Omega.PlanetMaterial", function(){
describe("#load", function(){
  it("loads texture corresponding to type", function(){
    var basepath = 'http://' + Omega.Config.http_host   +
                               Omega.Config.url_prefix  +
                               Omega.Config.images_path +
                               '/textures/planet';

    var mat = Omega.PlanetMaterial.load(0, function(){});
    assert(mat.map.image.src).equals(basepath + '0.png');

    mat = Omega.PlanetMaterial.load(1, function(){});
    assert(mat.map.image.src).equals(basepath + '1.png');
  });
});
});}); // Omega.PlanetMaterial
