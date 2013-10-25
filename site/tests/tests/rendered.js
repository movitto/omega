pavlov.specify("SolarSystem", function(){
describe("SolarSystem", function(){
  var sys;

  before(function(){
    sys  = new SolarSystem({id : 'sys1', location : {x:0,y:0,z:0}});
    clear_three_js();
  })

  describe("#add_jump_gate", function(){
    it("adds THREE line component to entity", function(){
      var jg = new JumpGate();
      var endpoint = new SolarSystem({location : {x:100,y:100,z:100}});
      sys.add_jump_gate(jg, endpoint);

      var comp = sys.components[sys.components.length-2];
      assert(comp.__proto__).equals(THREE.Line.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.LineBasicMaterial.prototype);
    });

    it("adds THREE particle effect component to entity", function(){
      var jg = new JumpGate();
      var endpoint = new SolarSystem({location : {x:100,y:100,z:100}});
      sys.add_jump_gate(jg, endpoint);

      var comp = sys.components[sys.components.length-1];
      assert(comp.__proto__).equals(THREE.ParticleSystem.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.ParticleBasicMaterial.prototype);
    });

    describe("current scene is set", function(){
      it("reloads entity", function(){
        var jg = new JumpGate();
        var endpoint = new SolarSystem({location : {x:100,y:100,z:100}});
        sys.current_scene = new Scene();
        var spy = sinon.spy(sys.current_scene, 'reload_entity')
        sys.add_jump_gate(jg, endpoint);
        sinon.assert.calledWith(spy, sys);
      });
    })
  });

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
    assert(comp.material.__proto__).equals(THREE.ShaderMaterial.prototype);
  });

  it("adds shader-based THREE glow component to entity", function(){
    var comp = star.glow;
    assert(comp.__proto__).equals(THREE.Mesh.prototype);

    // glow geometry is cloned from sphere geo,
    // glow just produces a THREE.Geometry instance
    assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
    assert(comp.material.__proto__).equals(THREE.ShaderMaterial.prototype);
  });
});});

pavlov.specify("Planet", function(){
describe("Planet", function(){
  var pl;

  before(function(){
    pl  = new Planet({id : 'pl1', color: 0x000000,
                      location : {x:0,y:0,z:10, movement_strategy : {}},
                      moons : [{id : 'mn1', location:{x:0,y:0,z:20}},
                               {id : 'mn2', location:{x:1,y:1,z:10}}]});
    clear_three_js();
  })

  describe("#update", function(){
    it("updates THREE sphere position", function(){
      pl.update({location : {x:10,y:-10,z:20}})
      assert(pl.sphere.position.x).equals(10);
      assert(pl.sphere.position.y).equals(-10);
      assert(pl.sphere.position.z).equals(20);
    });

    it("updates moons' THREE sphere positions", function(){
      pl.update({location:{x:10,y:-10,z:20}})
      assert(pl.moon_spheres[0].position.x).equals(10);
      assert(pl.moon_spheres[0].position.y).equals(-10);
      assert(pl.moon_spheres[0].position.z).equals(40);
      assert(pl.moon_spheres[1].position.x).equals(11);
      assert(pl.moon_spheres[1].position.y).equals(-9);
      assert(pl.moon_spheres[1].position.z).equals(30);
    });
  });

  it("adds THREE clickable sphere component to entity", function(){
    var comp = pl.components[0];
    assert(pl.clickable_obj).equals(comp);
    assert(comp.__proto__).equals(THREE.Mesh.prototype);
    assert(comp.geometry.__proto__).equals(THREE.SphereGeometry.prototype);
    assert(comp.material.__proto__).equals(THREE.MeshLambertMaterial.prototype);
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
    clear_three_js();
  })

  it("adds THREE clickable mesh component to entity", async(function(){
    var verified = false;
    UIResources().on('geometry_loaded', function(){
      if(verified || !ast || ast.components.length == 0) return;
      verified = true;
      var comp = ast.components[0];
      assert(ast.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshLambertMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
    ast  = new Asteroid({id : 'ast1'});
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
    var verified = false;
    UIResources().on('geometry_loaded', function(){
      if(verified || !jg || !jg.mesh) return;
      verified = true;
      var comp = jg.mesh;
      assert(jg.components).includes(comp);
      assert(jg.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshLambertMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
  }));

  it("adds lamp components to entity", function(){
    var comp = jg.lamp;
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
    var scene;

    before(function(){
      scene = new Scene();
    })

    it("sets clickable component to THREE selection sphere", function(){
      var comp = jg.sphere;
      jg.clicked_in(scene);
      assert(jg.components).includes(comp);
      assert(jg.clickable_obj).equals(comp);
    });

    it("reloads the entity in the scene", function(){
      var spy = sinon.spy(scene, 'reload_entity');
      jg.clicked_in(scene);
      sinon.assert.calledWith(spy, jg);
    })
  });

  describe("unselect jump gate", function(){
    var scene;

    before(function(){
      scene = new Scene();
      scene.add_entity(jg);
      jg.clicked_in(scene);
    })

    it("reloads the entity in the scene", function(){
      var spy = sinon.spy(scene, 'reload_entity');
      jg.unselected_in(scene);
      sinon.assert.calledWith(spy, jg);
    });

    it("removes selection sphere from scene", function(){
      var comp = jg.sphere;
      jg.unselected_in(scene);
      ok($.inArray(comp, jg.components) == -1);
    });

    it("sets clickable component to THREE mesh", function(){
      var comp = jg.mesh;
      jg.unselected_in(scene);
      assert(jg.clickable_obj).equals(comp);
    });
  });
});});

pavlov.specify("Ship", function(){
describe("Ship", function(){
  var sh;

  before(function(){
    clear_three_js();
  })

  // load ship after geometry callback registered
  function load_ship(){
    sh  = new Ship({id : 'sys1', type : 'corvette', hp : 100,
                    location : {x:0,y:0,z:0,
                                orientation_x:0,orientation_y:0,orientation_z:1}});
  }


  describe("#update", function(){
    it("updates THREE mesh location", async(function(){
      var verified = false;
      UIResources().on('geometry_loaded', function(r,e){
        if(verified || !sh || !sh.mesh) return;
        verified = true;
        sh.update({location:{x:10,y:-10,z:20}});
        assert(sh.mesh.position.x).equals(10);
        assert(sh.mesh.position.y).equals(-10);
        assert(sh.mesh.position.z).equals(20);
        resume();
      });
      load_ship();
    }));

    it("sets orientation on mesh", async(function(){
      var verified = false;
      UIResources().on('geometry_loaded', function(r,e){
        if(verified || !sh || !sh.mesh) return;
        verified = true;
        sh.update({location:{orientation_x:0,orientation_y:1,orientation_z:0}})
        assert(roundTo(sh.mesh.rotation.x,2)).equals(-1.57);
        assert(sh.mesh.rotation.y).equals(0);
        assert(sh.mesh.rotation.z).equals(0);
        resume();
      });
      load_ship();
    }));

    function load_trails(){
      var ot = [];
      var or = [];
      for(var i = 0; i < sh.trails.length; i++){
        var ox = sh.trails[i].position.x;
        var oy = sh.trails[i].position.y;
        var oz = sh.trails[i].position.z;
        var orx = sh.trails[i].rotation.x;
        var ory = sh.trails[i].rotation.y;
        var orz = sh.trails[i].rotation.z;
        ot.push([ox,oy,oz])
        or.push([orx,ory,orz])
      }

      return [ot, or];
    }

    it("updates THREE particle system trails position", function(){
      load_ship();
      var orig = load_trails();
      var ot = orig[0];

      sh.update({location:{x:10,y:10,z:10}});
      for(var i = 0; i < sh.trails.length; i++){
        assert(sh.trails[i].position.x).equals(ot[i][0] + 10);
        assert(sh.trails[i].position.y).equals(ot[i][1] + 10);
        assert(sh.trails[i].position.z).equals(ot[i][2] + 10);
      }
    });

    it("updates THREE particle system trails orientation", function(){
      load_ship();
      var orig = load_trails();
      var ot = orig[0]; var or = orig[1];

      sh.update({location:{orientation_x:1,orientation_y:0,orientation_z:0}});
      // XXX manually testing some static  known values,
      // should really iterate over original trail, rotating and
      // translating it and comparing to new trail rotation/porition
      //for(var i = 0; i < sh.trails.length; i++){
        assert(sh.trails[0].position.x).equals(-37.5);
        assert(sh.trails[0].position.y).equals(0);
        assert(roundTo(sh.trails[0].position.z,2)).equals(-10);
        assert(sh.trails[0].rotation.x).equals(0);
        assert(roundTo(sh.trails[0].rotation.y,2)).equals(1.57)
        assert(sh.trails[0].rotation.z).equals(0);
      //}
    });

    describe("ship is moving and trail components are not added", function(){
      it("adds trail components to entity", function(){
        load_ship();
        ok($.inArray(sh.components, sh.trails[0]) == -1)
        sh.update({location : {movement_strategy :
          {json_class : 'Motel::MovementStrategies::Linear'}}})
        for(var i = 0; i < sh.trails.length; i++)
          assert(sh.components).includes(sh.trails[i]);
      });
    });

    describe("ship is stopped and trail components are added", function(){
      it("removes trail components from entity", function(){
        load_ship();
        sh.update({location : {movement_strategy :
          {json_class :'Motel::MovementStrategies::Linear'}}})
        assert(sh.components).includes(sh.trails[0]);
        sh.update({location : {movement_strategy :
          {json_class : 'Motel::MovementStrategies::Stopped'}}})
        for(var i = 0; i < sh.trails.length; i++)
          ok($.inArray(sh.components, sh.trails[i]) == -1)
      });
    });

    describe("ship attacking", function(){
      it("sets THREE attack line position", function(){
        load_ship();
        var target = new Ship({location : {x:10,y:20,z:30}, type : 'mining'});
        sh.update({location : {x:100,y:100,z:200}, attacking : target})

        var dist = sh.location.distance_from(target.location.x,
                                             target.location.y,
                                             target.location.z)

        assert(sh.attack_particles.position.x).equals(100);
        assert(sh.attack_particles.position.y).equals(100);
        assert(sh.attack_particles.position.z).equals(200);
        assert(sh.attack_particles.geometry.scalex).equals(60 / dist * -90);
        assert(sh.attack_particles.geometry.scaley).equals(60 / dist * -80);
        assert(sh.attack_particles.geometry.scalez).equals(60 / dist * -170);
      });

      it("adds THREE attack line component to entity", function(){
        load_ship();
        ok($.inArray(sh.components, sh.attack_particles) == -1)
        var target = new Ship({location : {x:10,y:20,z:30}, type : 'mining'});
        sh.update({attacking : target})
        assert(sh.components).includes(sh.attack_particles);
      });
    });

    describe("ship not attacking", function(){
      it("removes THREE attack line component", function(){
        load_ship();
        var target = new Ship({location : {x:10,y:20,z:30}, type : 'mining'});
        sh.update({attacking : target})
        assert(sh.components).includes(sh.attack_particles);
        sh.update({});
        ok($.inArray(sh.components, sh.attack_particles) == -1)
      });
    })

    function load_resource(sys){
      var ast  = new Asteroid({id : 'ast1', system_id : sys,
                               location : {x:20,y:20,z:30}});
      var ssys = new SolarSystem({id:sys, children : [ast]})
      Entities().set(sys, ssys);
      var resource = {entity_id: ast.id};
      return resource;
    }

    describe("ship mining", function(){
      it("sets THREE mining line position", function(){
        load_ship();
        sh.system_id = 'system1'

        var resource = load_resource('system1');
        sh.update({mining: resource, location : {x:100,y:100,z:200}})

        assert(sh.mining_line.geometry.vertices[0].x).equals(100);
        assert(sh.mining_line.geometry.vertices[0].y).equals(100);
        assert(sh.mining_line.geometry.vertices[0].z).equals(200);
        assert(sh.mining_line.geometry.vertices[1].x).equals(20);
        assert(sh.mining_line.geometry.vertices[1].y).equals(20);
        assert(sh.mining_line.geometry.vertices[1].z).equals(30);
      });

      it("adds THREE mining line component to entity", function(){
        load_ship();
        sh.system_id = 'system1'

        var resource = load_resource('system1');
        ok($.inArray(sh.components, sh.mining_line) == -1)
        sh.update({mining: resource, location : {x:100,y:100,z:200}})
        assert(sh.components).includes(sh.mining_line);
      });
    });

    describe("ship not mining", function(){
      it("removes mining line component", function(){
        load_ship();
        sh.system_id = 'system1'

        var resource = load_resource('system1')
        sh.update({mining: resource, location : {x:100,y:100,z:200}})

        assert(sh.components).includes(sh.mining_line);
        sh.update({});
        ok($.inArray(sh.components, sh.mining_line) == -1)
      })
    });

    describe("ship is selected", function(){
      it("sets mesh emissive color", async(function(){
        var verified = false;
        UIResources().on('geometry_loaded', function(){
          if(verified || !sh || !sh.mesh) return;
          verified = true;
          sh.selected = true;
          sh.update({});
          assert(sh.mesh.material.emissive.getHex()).equals(0xff0000)
          resume();
        });
        load_ship();
      }));
    });

    describe("ship is not selected", function(){
      it("resets ship emissive color", async(function(){
        var verified = false;
        UIResources().on('geometry_loaded', function(){
          if(verified || !sh || !sh.mesh) return;
          verified = true;
          sh.selected = true;
          sh.update({});
          sh.selected = false;
          sh.update({});
          assert(sh.mesh.material.emissive.getHex()).equals(0);
          resume();
        });
        load_ship();
      }));
    });
  })

  it("adds THREE clickable mesh component to entity", async(function(){
    var verified = false;
    UIResources().on('geometry_loaded', function(){
      var comp = sh.mesh;
      if(verified || comp == null) return;
      verified = true;
      assert(sh.components).includes(comp);
      assert(sh.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshLambertMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
    load_ship();
  }));

  it("creates THREE particle system trails", function(){
    load_ship();
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
    load_ship();
    var comp = sh.attack_particles;
    assert(comp.__proto__).equals(THREE.ParticleSystem.prototype);
    assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
    assert(comp.material.__proto__).equals(THREE.ParticleBasicMaterial.prototype);
  });

  it("create THREE line component (for mining line)", function(){
    load_ship();
    var comp = sh.mining_line;
    assert(comp.__proto__).equals(THREE.Line.prototype);
    assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
    assert(comp.material.__proto__).equals(THREE.LineBasicMaterial.prototype);
  });

  //describe("updating ship trails particles", function(){
  //  it("moves linearily away from ship"); // NIY
  //  it("decays with a given lifespan"); // NIY
  //  it("sets lifespan of center particles to greater than outer particles") // NIY
  //});
  //
  //describe("updating ship attack particles", function(){
  //  it("moves particles linearily between attacker location and defender location"); // NIY
  //  describe("particle arriving at defender location", function(){
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
    var verified = false;
    UIResources().on('geometry_loaded', function(){
      if(verified || !st || st.mesh == null) return;
      verified = true;
      var comp = st.mesh;
      assert(st.clickable_obj).equals(comp);
      assert(comp.__proto__).equals(THREE.Mesh.prototype);
      assert(comp.geometry.__proto__).equals(THREE.Geometry.prototype);
      assert(comp.material.__proto__).equals(THREE.MeshLambertMaterial.prototype);
      assert(comp.material.map.__proto__).equals(THREE.Texture.prototype);
      resume();
    })
  }));
});});

pavlov.specify("Skybox", function(){
describe("Skybox", function(){
  it("adds THREE skybox mesh component to entity", function(){
    var sb = new Skybox();
    sb.background('galaxy2');
    assert(sb.components.length).equals(1)
    assert(sb.components[0].__proto__).equals(THREE.Mesh.prototype);
    assert(sb.components[0].geometry.__proto__).equals(THREE.CubeGeometry.prototype);
    assert(sb.components[0].material.__proto__).equals(THREE.ShaderMaterial.prototype);
  });
});});
