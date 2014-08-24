pavlov.specify("Omega.AsteroidCommands", function(){
describe("Omega.AsteroidCommands", function(){
  describe("#retrieve_details", function(){
    var ast, page, details_cb;

    before(function(){
      ast = new Omega.Asteroid({id       : 'ast1i',
                                name     : 'ast1',
                                location : new Omega.Location({x:100,y:-200,z:50.5678})});
      page = new Omega.Pages.Test({node : new Omega.Node()});
      details_cb = sinon.spy();
    });

    after(function(){
      if(page.node.http_invoke.restore) page.node.http_invoke.restore();
    });

    it("invokes details cb with asteroid name / location", function(){
      var expected = 'Asteroid: ast1<br/>@ 1.00e+2/-2.00e+2/5.06e+1<br/>';
      ast.retrieve_details(page, details_cb)
      sinon.assert.calledWith(details_cb, expected);
    });

    it("invokes cosmos::get_resources request with page node", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ast.retrieve_details(page, details_cb);
      sinon.assert.calledWith(http_invoke,
        'cosmos::get_resources', 'ast1i', sinon.match.func);
    });

    describe("on resources retrieval", function(){
      it("invokes resources_retrieved", function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ast.retrieve_details(page, details_cb);

        var retrieve_cb = http_invoke.getCall(0).args[2];
        var resources_retrieved = sinon.spy(ast, '_resources_retrieved');
        var response = {result: []};
        retrieve_cb(response);

        sinon.assert.calledWith(resources_retrieved, response, details_cb);
      });
    });
  });

  describe("#_resources_retrieved", function(){
    var ast, details_cb;

    before(function(){
      ast = new Omega.Asteroid({});
      details_cb = sinon.spy();
    });

    describe("error on retrieval", function(){
      it("invokes details cb with error", function(){
        var response = {error : {message : 'resources_error'}};
        ast._resources_retrieved(response, details_cb);

        var expected = 'Could not load resources: resources_error';
        sinon.assert.calledWith(details_cb, expected);
      });
    });

    describe("successful retrieval", function(){
      it("invokes details cb with resources retrieved", function(){
        var res1 = {id : 'res1', quantity: 50, material_id: 'gold'};
        var res2 = {id : 'res2', quantity: 10, material_id: 'ruby'};
        var resources = [res1, res2];
        var response  = {result: resources};
        var expected  = 'Resource: res1<br/>' +
                        '50 of gold<br/>'     +
                        'Resource: res2<br/>' +
                        '10 of ruby<br/>'     ;

        ast._resources_retrieved(response, details_cb);
        sinon.assert.calledWith(details_cb, expected);
      });
    });
  });
});});
