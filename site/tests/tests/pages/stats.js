pavlov.specify("Omega.Pages.Stats", function(){
describe("Omega.Pages.Stats", function(){
   var old_cookies, stats;

   before(function(){
     old_cookies = Omega.Session.cookies_enabled;
     page = new Omega.Pages.Stats();
   });

   after(function(){
     Omega.Session.cookies_enabled = old_cookies;
     if(Omega.Session.login.restore) Omega.Session.login.restore();
   });

  describe("#login", function(){
    it("disables session cookies", function(){
      page.login();
      assert(Omega.Session.cookies_enabled).isFalse();
    });

    it("logins anon user", function(){
      var login = sinon.spy(Omega.Session, 'login');
      page.login();
      sinon.assert.calledWith(login,
         sinon.match.ofType(Omega.User), page.node);
      var user = login.getCall(0).args[0];
      assert(user.id).equals(Omega.Config.anon_user)
      assert(user.password).equals(Omega.Config.anon_pass)
    });
  });

  describe("#start", function(){
    after(function(){
      page.stats_timer.stop();
      if($.timer.restore) $.timer.restore();
    });

    it("creates stats timer", function(){
      page.start();
      assert(page.stats_timer.clearTimer).isNotNull(); /// XXX
    });

    describe("stats timer cycle", function(){
      it("retreives stats", function(){
        var timer = sinon.spy($, 'timer');
        page.start();

        var timer_cb = timer.getCall(0).args[0];
        var retrieve_stats = sinon.spy(page, 'retrieve_stats');
        timer_cb();
        sinon.assert.calledWith(retrieve_stats);
      });
    });
  });

  describe("#retrieve_stats", function(){
    var old_stats;

    before(function(){
      old_stats = Omega.Config.stats;
      Omega.Config.stats = [['stat1', ['stat1args']],
                            ['stat2', ['stat2args']]];
    });

    after(function(){
      Omega.Config.stats = old_stats;
      if(Omega.Stat.get.restore) Omega.Stat.get.restore();
    });

    it("retrieves configured omega stats", function(){
      var get = sinon.spy(Omega.Stat, 'get');
      page.retrieve_stats();
      sinon.assert.calledWith(get, 'stat1', ['stat1args'], page.node, sinon.match.func);
      sinon.assert.calledWith(get, 'stat2', ['stat2args'], page.node, sinon.match.func);
    });

    describe("omega stat retrieved", function(){
      var get_cb, stat;

      before(function(){
        var get = sinon.stub(Omega.Stat, 'get');
        page.retrieve_stats();
        get_cb = get.getCall(0).args[3];

        stat = new Omega.Stat({stat: {stat_id : 'sid'}});
      });

      it("updates stats", function(){
        var update_stats = sinon.spy(page, 'update_stats');
        get_cb(stat)
        sinon.assert.calledWith(update_stats, stat);
      });

      it("refreshes stats", function(){
        var refresh_stats = sinon.spy(page, 'refresh_stats');
        get_cb(stat)
        sinon.assert.called(refresh_stats);
      });
    });
  });

  describe("#update_stats", function(){
    var stats, stats1;
    before(function(){
      stat  = new Omega.Stat({stat : {stat_id : 'stat1'}});
      stat1 = new Omega.Stat({stat : {stat_id : 'stat1'}});
    });

    it("stores stats locally", function(){
      page.update_stats(stat);
      assert(page.stat_results['stat1']).equals(stat);
    });

    it("overwrites duplicate stats", function(){
      page.update_stats(stat);
      page.update_stats(stat1);
      assert(page.stat_results['stat1']).equals(stat1);
    });
  });

  describe("refresh_stats", function(){
    it("adds stats to ui", function(){
      $('#stats ul').html('<li>foo</li>');
      page.stat_results =
        {'stat1' : new Omega.Stat({value : 10, stat :
                         {stat_id : 'stat1',
                          description : 'dstat1'}}),
         'stat2' : new Omega.Stat({value : 20, stat :
                         {stat_id : 'stat2',
                          description: 'dstat2'}})};

      page.refresh_stats();
      var text = $('#stats ul').html();
      assert(text).equals('<li>dstat1: 10</li><li>dstat2: 20</li>');
    });
  });
});});
