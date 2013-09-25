pavlov.specify("SolarSystem", function(){
describe("SolarSystem", function(){
  var sys;

  before(function(){
    sys  = new SolarSystem({id : 'sys1'});
    clear_three_js();
  })

  //describe("#add_jump_gate", function(){
  //  it("adds THREE line component to entity"); // NIY
  //});

  it("adds THREE clickable sphere component to entity", function(){
    var comp = sys.components[0];
    assert(sys.clickable_obj).equals(comp);
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
    // TODO verify color,transparency,etc
  });

  it("adds THREE plane component to entity", function(){
    var comp = sys.components[1];
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.PlaneGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
  });

  it("adds THREE text label component to entity", function(){
    var comp = sys.components[2];
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.TextGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
  });
});});

pavlov.specify("Star", function(){
describe("Star", function(){
  var star;

  before(function(){
    star  = new Star({id : 'st1'});
    clear_three_js();
  })

  it("adds THREE sphere component to entity", function(){
    var comp = star.sphere;
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
  });

  it("adds clickable shader-based THREE glow component to entity", function(){
    var comp = star.glow;
    assert(star.clickable_obj).equals(comp);
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.ShaderMaterial.prototype);
  });

  it("adds THREE flare component to entity", function(){
    var comp = star.components[0];
    assert(comp.__proto__).equals(THREE.LensFlare.prototype);
  });

  describe("added to scene", function(){
    it("sets glow view vector", function(){
      var scene = new Scene();
      star.added_to(scene);
      assert(star.glow.material.uniforms.viewVector.value).
        equals(scene.camera._camera.position);
    });
  });
});});

pavlov.specify("Planet", function(){
describe("Planet", function(){
  var pl;

  before(function(){
    pl  = new Planet({id : 'pl1', color: 0x000000,
                      location : {movement_strategy : {}},
                      moons : [{location:{}}, {location:{}}]});
    clear_three_js();
  })

  describe("#update", function(){
    //it("updates THREE sphere position") // NIY

    //it("updates moons' THREE sphere positions", function(){ // NIY
    //  var nmn = { id : 'mn1'}
    //  pl.update({moons : [nmn]})
    //  sinon.assert.calledWith(spy, nmn);
    //});
  });

  it("adds THREE clickable sphere component to entity", function(){
    var comp = pl.components[0];
    assert(pl.clickable_obj).equals(comp);
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
    assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
  });

  it("adds THREE line component to entity for orbit", function(){
    var comp = pl.components[1];
    assert(comp.__proto__).equals(THREE.Line.prototype);
    assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
    assert(comp.material.__proto__).equals(THREE.LineBasicMaterial.prototype);
  });

  it("adds THREE spheres component to entity for moons", function(){
    var mcomp1 = pl.components[2];
    var mcomp2 = pl.components[3];
    assert(mcomp1.__proto__).equals(THREE.Mesh.prototype);
    assert(mcomp2.__proto__).equals(THREE.Mesh.prototype);
    assert(mcomp1.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(mcomp1.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
    assert(mcomp2.geometry).equals(mcomp1.geometry)
    assert(mcomp2.material).equals(mcomp1.material)
  });
});});

pavlov.specify("Asteroid", function(){
describe("Asteroid", function(){
  var ast;

  before(function(){
    ast  = new Asteroid({id : 'ast1'});
    clear_three_js();
  })

  it("adds THREE clickable mesh component to entity", async(function(){
    UIResources().on('geometry_loaded', function(){
      var comp = ast.components[0];
      assert(ast.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
  }));
});});

pavlov.specify("JumpGate", function(){
describe("JumpGate", function(){
  var jg;

  before(function(){
    jg  = new JumpGate({id : 'jg1'});
    clear_three_js();
  })

  it("adds THREE clickable mesh component to entity", async(function(){
    UIResources().on('geometry_loaded', function(){
      var comp = jg.mesh;
      assert(jg.components).includes(comp);
      assert(jg.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
  }));

  it("adds THREE light components to entity", function(){
    var comp = jg.light1;
    assert(jg.components).includes(comp);
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
  });

  it("adds THREE particle system components to entity (effects)", function(){
    var comp = jg.effects1;
    assert(jg.components).includes(comp);
    assert(comp.__proto__).equals(THREE.ParticleSystem.prototype);
    assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
    assert(comp.material.__proto__).equals(THREE.ParticleBasicMaterial.prototype);
  });

  it("adds THREE sphere component to entity (selection sphere)", function(){
    var comp = jg.sphere;
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
  });

  describe("clicked jump gate", function(){
    // it("sets clickable component to THREE selection sphere"); // NIY
  });

  describe("unselect jump gate", function(){
    //it("removes selection sphere from scene"); // NIY
    //it("sets clickable component to THREE mesh"); // NIY
  });
});});

pavlov.specify("Ship", function(){
describe("Ship", function(){
  var sh;

  before(function(){
    sh  = new Ship({id : 'sys1', type : 'corvette', hp : 100});
    clear_three_js();
  })


  describe("#update", function(){
  //  it("updates THREE mesh location"); // NIY
  //  it("sets orientation on mesh") // NIY
  //  it("updates THREE particle system trails position") // NIY
  //  it("sets orientation of trails")
  //  context("ship is moving and trail components are not added", function(){
  //    it("adds trail components to entity");
  //  });
  //  context("ship is stopped and trail components are added", function(){
  //    it("removes trail components from entity");
  //  });
  //  context("ship attacking", function(){
  //    it("sets THREE attack line position"); // NIY
  //    it("adds THREE attack line component to entity"); // NIY
  //  });
  //  context("ship mining", function(){
  //    it("sets THREE mining line position"); // NIY
  //    it("adds THREE mining line component to entity"); // NIY
  //  });
  //  context("ship is selected", function(){
  //    it("sets mesh emissive color") // NIY
  //  });
  //  context("ship is not selected", function(){
  //    it("resets ship emissive color"); // NIY
  //  });
  })

  it("adds THREE clickable mesh component to entity", async(function(){
    UIResources().on('geometry_loaded', function(){
      var comp = sh.mesh;
      if(comp == null) return;
      assert(sh.components).includes(comp);
      assert(sh.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshLambertMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
  }));

  it("creates THREE particle system trails", function(){
    var comp = sh.trails;
    assert(comp.length).isGreaterThan(0); // # of trails depends on config,
                                          // ensure we're generating at least 1

    for(var t = 0; t < sh.trails.length; t++){
      var trail = sh.trails[t];
      assert(trail.__proto__).equals(THREE.ParticleSystem.prototype);
      assert(trail.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(trail.material.__proto__).equals(THREE.ParticleBasicMaterial.prototype);
    }
  });

  it("create THREE partitcle system component (for attack)", function(){
    var comp = sh.attack_particles;
    assert(comp.__proto__).equals(THREE.ParticleSystem.prototype);
    assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
    assert(comp.material.__proto__).equals(THREE.ParticleBasicMaterial.prototype);
  });

  it("create THREE line component (for mining line)", function(){
    var comp = sh.mining_line;
    assert(comp.__proto__).equals(THREE.Line.prototype);
    assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
    assert(comp.material.__proto__).equals(THREE.LineBasicMaterial.prototype);
  });

  //context("updating ship trails particles", function(){
  //  it("moves linearily away from ship"); // NIY
  //  it("decays with a given lifespan"); // NIY
  //  it("sets lifespan of center particles to greater than outer particles") // NIY
  //});
  //
  //context("updating ship attack particles", function(){
  //  it("moves particles linearily between attacker location and defender location"); // NIY
  //  context("particle arriving at defender location", function(){
  //    it("resets particle to originating from attacker location"); // NIY
  //  });
  //});
});});

pavlov.specify("Station", function(){
describe("Station", function(){
  var st;

  before(function(){
    st  = new Station({id : 'sys1', type : 'manufacturing'});
    clear_three_js();
  })

  it("adds THREE clickable mesh component to entity", async(function(){
    UIResources().on('geometry_loaded', function(){
      var comp = st.components[0];
      assert(st.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshBasicMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
  }));
});});

pavlov.specify("Skybox", function(){
describe("Skybox", function(){
  it("adds THREE skybox mesh component to entity", function(){
    var sb = new Skybox();
    sb.background('galaxy1');
    assert(sb.components.length).equals(1)
    assert(sb.components[0].__proto__).equals(THREE.Mesh.prototype);
    assert(sb.components[0].geometry.__proto__).equals(THREE.CubeGeometry.prototype);
    assert(sb.components[0].material.__proto__).equals(THREE.MeshFaceMaterial.prototype);
  });
});});
