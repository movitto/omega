pavlov.specify("Omega.UI.StatusIndicator", function(){
describe("Omega.UI.StatusIndicator", function(){
  var si;
  before(function(){
    si = new Omega.UI.StatusIndicator({page: Omega.Test.Page()});
  })

  describe("#background", function(){
    it("sets component background", function(){
      si.background('foobar');
      assert(si.component().css('background-image')).isNotEqualTo('') // TODO better regex based match
    });

    describe("specified background is null", function(){
      it("clears component background", function(){
        si.background();
        assert(si.component().css('background-image')).equals('none')
      });
    });
  });

  describe("#has_state", function(){
    describe("state is on state stack", function(){
      it("returns true", function(){
        si.push_state('st1');
        assert(si.has_state('st1')).isTrue();
      });
    });
    describe("state is not on state stack", function(){
      it("returns false", function(){
        assert(si.has_state('st1')).isFalse();
      });
    });
  });

  describe("#is_state", function(){
    describe("state is last state stack", function(){
      it("returns true", function(){
        si.push_state('st1');
        si.push_state('st2');
        assert(si.is_state('st2')).isTrue();
      });
    });

    describe("state is not last state on stack", function(){
      it("returns false", function(){
        si.push_state('st1');
        si.push_state('st2');
        assert(si.is_state('st1')).isFalse();
      });
    });
  });

  describe("push_state", function(){
    it("pushes new state onto stack", function(){
      si.push_state('st1');
      assert(si.has_state('st1')).isTrue();
    });

    it("sets background", function(){
      var spy = sinon.spy(si, 'background')
      si.push_state('st1')
      sinon.assert.calledWith(spy, 'st1');
    });
  });

  describe("pop_state", function(){
    it("pops a state off stack", function(){
      si.push_state('st1');
      si.pop_state();
      assert(si.has_state('st1')).isFalse();
    });

    it("sets background", function(){
      var spy = sinon.spy(si, 'background')
      si.push_state('st1')
      si.push_state('st2')
      si.pop_state();
      sinon.assert.calledWith(spy, 'st1');
      si.pop_state();
      sinon.assert.calledWith(spy, null);
    });
  });

  describe("#clear", function(){
    it("clears all stats from status indicator", function(){
      si.push_state('st1');
      si.clear();
      assert(si.has_state('st1')).isFalse();
    });

    it("clears background", function(){
      var set_bg = sinon.spy(si, 'background')
      si.clear();
      sinon.assert.calledWith(set_bg, null);
    });
  })

  describe("#follow_node", function(){
    var node;

    before(function(){
      node = new Omega.Node();
    })

    it("pushes state on node request events", function(){
      si.follow_node(node, 'loading');
      node.http_invoke();
      assert(si.has_state('loading')).isTrue();
    });

    it("pops state on node response events", function(){
      si.follow_node(node, 'loading');
      node.http_invoke();
      node._http_msg_received({id: 'foo'}); /// response has request id
      assert(si.has_state('loading')).isFalse();
    });

    it("does nothing on node notify events", function(){
      si.follow_node(node, 'loading');
      node.http_invoke();
      node._http_msg_received({}); /// notifications have no id
      assert(si.has_state('loading')).isTrue();
    });

    it("clears states on node disconnection errors", function(){
      var clear = sinon.spy(si, 'clear');
      si.follow_node(node, 'loading');
      node.dispatchEvent({type: 'error', disconnected : true});
      sinon.assert.called(clear);
    })
  });

  describe("#animate", function(){
    var url;
    before(function(){
      url = 'url("http://localhost/omega-test/foo")'; /// XXX
    })

    describe("background is set", function(){
      it("stores background", function(){
        si.component().css('background', 'url("foo")');
        si.animate();
        assert(si.original_bg).equals(url);
      })

      it("clears background", function(){
        si.component().css('background-image', 'foo');
        si.animate();
        assert(si.component().css('background-image')).equals('none');
      })
    });

    describe("background is not set", function(){
      it("restores background", function(){
        si.original_bg = 'url("foo")';
        si.component().css('background-image', '');
        si.animate();
        assert(si.component().css('background-image')).equals(url);
      })
    });
  });
});}); // Omega.UI.StatusIndicator
