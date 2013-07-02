// TODO test specific entity ui components / operations

pavlov.specify("Entities", function(){
describe("Entities", function(){
  before(function(){
  });

  it("provides global entities registry");
  it("provides global node");

});}); // Entities

pavlov.specify("Entity", function(){
describe("Entity", function(){
  before(function(){
  });

  describe("#update", function(){
    it("copies all attributes from specified object")
  });

  it("initializes attributes from args")

  describe("toJSON", function(){
    it("returns entity in json format")
  })

});}); // Entities

pavlov.specify("User", function(){
describe("User", function(){
  describe("#is_anon", function(){
    describe("user is configured anon user", function(){
      it("returns true");
    });
    describe("user is not configured anon user", function(){
      it("returns false");
    });
  });

  describe("#anon_user", function(){
    it("returns user instance from configured anon user");
  })
});}); // User

pavlov.specify("Location", function(){
describe("Location", function(){
  describe("#distance_from", function(){
    it("returns distance from location to specified coordiante");
  })

  describe("#is_within", function(){
    describe("location is within distance of other location", function(){
      it("returns true");
    })

    describe("location is not within distance of other location", function(){
      it("returns false");
    })
  })
});}); // Location

pavlov.specify("Galaxy", function(){
describe("Galaxy", function(){
  describe("#update", function(){
    it("updates attributes");
    it("updates location");
    it("updates solar systems");
    it("invoked entity update method");
  })

  it("converts location")
  it("converts solar system children")

  describe("#children", function(){
    it("returns child solar systems")
  })

  describe("#with_name", function(){
    it('invokes cosmos::get_entity');
    describe("succesfull get_entity response", function(){
      it("creates new galaxy");
      it("invokes callback with galaxy");
    })
  })
});}); // Galaxy

pavlov.specify("SolarSystem", function(){
describe("SolarSystem", function(){
  describe("#update", function(){
    it("updates attributes");
    it("updates location");
    it("updates star");
    it("updates planets");
    it("updates asteroids");
    it("updates jump gates");
    it("invoked entity update method");
  })

  it("converts location")
  it("converts child star");
  it("converts child planets");
  it("converts child asteroids");
  it("converts child jump gates");

  describe("#children", function(){
    it("returns child star, planets, asteroids, jump gates, and manu entities")
  })

  describe("#with_name", function(){
    it('invokes cosmos::get_entity');
    describe("succesfull get_entity response", function(){
      it("creates new solar system");
      it("invokes callback with solar system");
    })
  })

  describe("#entities_under", function(){
    it('invokes manufactured::get_entities')
    describe("succesfull get_entities response", function(){
      it("instantiates ships/stations")
      it("invokes callback with entities")
    });
  })
});}); // SolarSystem

pavlov.specify("Star", function(){
describe("Star", function(){
  it("converts location")
});}); // Star

pavlov.specify("Planet", function(){
describe("Planet", function(){
  it("converts location")

  describe("#update", function(){
    it("updates attributes");
    it("updates location");
    it("updates moons");
  });
});}); // Planet

pavlov.specify("Asteroid", function(){
describe("Asteroid", function(){
  it("converts location")
});}); // Asteroid

pavlov.specify("JumpGate", function(){
describe("JumpGate", function(){
  it("converts location")

  describe("#update", function(){
    it("updates attributes");
    it("updates location");
  });
});}); // JumpGate

pavlov.specify("Ship", function(){
describe("Ship", function(){
  it("converts location")

  describe("#belongs_to_user", function(){
    describe("user_id is same as specified user's", function(){
      it("returns true")
    })
    describe("user_id is not same as specified user's", function(){
      it("returns false")
    })
  });

  describe("#belongs_to_current_user", function(){
    describe("user_id is same as current user's", function(){
      it("returns true")
    })
    describe("user_id is not same as current user's", function(){
      it("returns false")
    })
  });

  describe("#with_id", function(){
    it("invokes manufactured::get_entity")
    describe("successful get_entity response", function(){
      it("creates ship")
      it("invokes callback with ship")
    })
  })

  describe("#owned_by", function(){
    it("invokes manufactured::get_entities")
    describe("successful get_entities response", function(){
      it("creates ships")
      it("invokes callback with ships")
    })
  })
});}); // Ship

pavlov.specify("Station", function(){
describe("Station", function(){
  it("converts location")

  describe("#belongs_to_user", function(){
    describe("user_id is same as specified user's", function(){
      it("returns true")
    })
    describe("user_id is not same as specified user's", function(){
      it("returns false")
    })
  });

  describe("#belongs_to_current_user", function(){
    describe("user_id is same as current user's", function(){
      it("returns true")
    })
    describe("user_id is not same as current user's", function(){
      it("returns false")
    })
  });

  describe("#owned_by", function(){
    it("invokes manufactured::get_entities")
    describe("successful get_entities response", function(){
      it("creates stations")
      it("invokes callback with stations")
    })
  })
});}); // Station

pavlov.specify("Mission", function(){
describe("Mission", function(){
  describe("#expires", function(){
    it("returns Date which mission expires at")
  })

  describe("#expired", function(){
    describe("mission expired", function(){
      it("returns true")
    });
    describe("mission not expired", function(){
      it("returns false")
    });
  })

  describe("#assigned_to_user", function(){
    describe("assigned_to_id is same as specified user's", function(){
      it("returns true")
    })
    describe("assigned_to_id is not same as specified user's", function(){
      it("returns false")
    })
  });

  describe("#assigned_to_current_user", function(){
    describe("assigned_to_id is same as current user's", function(){
      it("returns true")
    })
    describe("assigned_to_id is not same as current user's", function(){
      it("returns false")
    })
  });

  describe("#all", function(){
    it("invokes missions::get_missions")
    describe("successful mission retrieval", function(){
      it("instantiates missions")
      it("invokes callback with missions")
    })
  })
});}); // Mission

pavlov.specify("Statistic", function(){
describe("Statistic", function(){
  describe("#with_id", function(){
    it("invokes stats::get")
    describe("successful get response", function(){
      it("creates stat")
      it("invokes callback with stat")
    })
  })
});}); // Statistic
