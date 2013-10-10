/* Omega Javascript Canvas Components
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Instantiate and return a new Skybox
 */
function Skybox(args){
  /////////////////////////////////////// public data
  $.extend(this, new CanvasComponent(args));

  /////////////////////////////////////// private data
  var skyboxMesh = null;

  var size = 32768;

  /////////////////////////////////////// public methods

  this.background = function(new_background){
    if(new_background){
      this.bg = new_background;

      var size   = 32768;
      var format = 'png';
      var path   = UIResources().images_path +
                   '/skybox/' + this.bg + '/';
      var materials = [
        path + 'px.' + format,
        path + 'nx.' + format,
        path + 'pz.' + format,
        path + 'nz.' + format,
        path + 'py.' + format,
        path + 'ny.' + format
      ];

      skybox_mesh =
        UIResources().cached('skybox_'+this.bg+'_mesh',
          function(i){
            var geometry = new THREE.CubeGeometry(size, size, size,
                                                  7, 7, 7);
            //var material = new THREE.MeshFaceMaterial();
            var shader = THREE.ShaderLib["cube"];
            shader.uniforms["tCube"].value = UIResources().load_texture_cube(materials);
            var material = new THREE.ShaderMaterial({
              fragmentShader : shader.fragmentShader,
              vertexShader   : shader.vertexShader,
              uniforms       : shader.uniforms,
              depthWrite     : false,
              side           : THREE.BackSide
            })

            var skyboxMesh = new THREE.Mesh(geometry, material);
            //skyboxMesh.scale.x = - 1;
            return skyboxMesh;
          });
      this.components = [skybox_mesh];
    }
    return this.bg;
  }
}

/* Instantiate and return a new Axis
 */
function Axis(args){
  /////////////////////////////////////// public data
  $.extend(this, new UIComponent(args));
  $.extend(this, new CanvasComponent(args));

  this.scene = args['scene'];

  this.div_id = '#toggle_axis_canvas';
  this.toggle_canvas_id = this.div_id;
  this.on('toggle', function(a){ this.scene.animate(); });

  this.num_markers = 3; // should be set to number of
                        // elements in distance_geometries

  /////////////////////////////////////// private data
  var size = 8192;

  var line_geometry =
    UIResources().cached('axis_geometry',
      function(i) {
        var geo = new THREE.Geometry();
        geo.vertices.push( new THREE.Vector3( 0, 0, -size ) );
        geo.vertices.push( new THREE.Vector3( 0, 0,  size ) );

        geo.vertices.push( new THREE.Vector3( 0, -size, 0 ) );
        geo.vertices.push( new THREE.Vector3( 0,  size, 0 ) );

        geo.vertices.push( new THREE.Vector3( -size, 0, 0 ) );
        geo.vertices.push( new THREE.Vector3(  size, 0, 0 ) );

        return geo;
      });

  var line_material =
    UIResources().cached('axis_material',
      function(i) {
        return new THREE.LineBasicMaterial( { color: 0xcccccc,
                                              opacity: 0.4 } );
      })

  var distance_geometries =
    UIResources().cached('axis_distance_geometries',
      function(i) {
        return [new THREE.TorusGeometry(3000, 5, 40, 40),
                new THREE.TorusGeometry(2000, 5, 20, 20),
                new THREE.TorusGeometry(1000, 5, 20, 20)];
      });

  var distance_material =
    UIResources().cached('axis_distance_material',
      function(i) {
        return new THREE.MeshBasicMaterial({color: 0xcccccc });
      });

  var line =
    UIResources().cached('axis_line',
      function(i){
        return new THREE.Line(line_geometry, line_material,
                              THREE.LinePieces );
      });
  this.components.push(line);

  var distance_markers =
    UIResources().cached('axis_distance_markers',
      function(i){
        var dm = [];
        for(var geometry = 0; geometry < distance_geometries.length; geometry++){
          var mesh = new THREE.Mesh(distance_geometries[geometry],
                                    distance_material);
          mesh.position.x = 0;
          mesh.position.y = 0;
          mesh.position.z = 0;
          mesh.rotation.x = 1.57;
          dm.push(mesh);
        }

        return dm
      });
  for(var dm in distance_markers)
    this.components.push(distance_markers[dm]);
}

/* Instantiate and return a new Grid
 */
function Grid(args){
  /////////////////////////////////////// public data
  $.extend(this, new UIComponent(args));
  $.extend(this, new CanvasComponent(args));

  this.scene = args['scene'];

  this.div_id = '#toggle_grid_canvas';
  this.toggle_canvas_id = this.div_id;
  this.on('toggle', function(a){ this.scene.animate(); });

  /////////////////////////////////////// private data
  var size = 5000;

  var step = 1000;

  var line_geometry =
    UIResources().cached('grid_geometry',
                         function(i) {
                           var geo = new THREE.Geometry();

                           // create line representing entire grid
                           for ( var i = - size; i <= size; i += step ) {
                             for ( var j = - size; j <= size; j += step ) {
                               /////////////////////////// 'cube' grid:
                               // geo.vertices.push( new THREE.Vector3( - size, j, i ) );
                               // geo.vertices.push( new THREE.Vector3(   size, j, i ) );

                               // geo.vertices.push( new THREE.Vector3( i, j, - size ) );
                               // geo.vertices.push( new THREE.Vector3( i, j,   size ) );

                               // geo.vertices.push( new THREE.Vector3( i, -size, j ) );
                               // geo.vertices.push( new THREE.Vector3( i, size,  j ) );

                               /////////////////////////// 'plane' grid:
                               // xy
                               geo.vertices.push( new THREE.Vector3( - size, j, 0 ) );
                               geo.vertices.push( new THREE.Vector3(   size, j, 0 ) );
                               geo.vertices.push( new THREE.Vector3( - size, -j, 0 ) );
                               geo.vertices.push( new THREE.Vector3(   size, -j, 0 ) );

                               geo.vertices.push( new THREE.Vector3( j, -size, 0 ) );
                               geo.vertices.push( new THREE.Vector3( j, size, 0 ) );
                               geo.vertices.push( new THREE.Vector3( -j, -size, 0 ) );
                               geo.vertices.push( new THREE.Vector3( -j, -size, 0 ) );

                               // yz
                               //geo.vertices.push( new THREE.Vector3( 0, j,   size ) );
                               //geo.vertices.push( new THREE.Vector3( 0, j, - size ) );
                               //geo.vertices.push( new THREE.Vector3( 0, -j,   size ) );
                               //geo.vertices.push( new THREE.Vector3( 0, -j, - size ) );

                               //geo.vertices.push( new THREE.Vector3( 0, size,  j ) );
                               //geo.vertices.push( new THREE.Vector3( 0, -size, j ) );
                               //geo.vertices.push( new THREE.Vector3( 0, size,  -j ) );
                               //geo.vertices.push( new THREE.Vector3( 0, -size, -j ) );

                               // xz
                               geo.vertices.push( new THREE.Vector3( j, 0,   size ) );
                               geo.vertices.push( new THREE.Vector3( j, 0, - size ) );
                               geo.vertices.push( new THREE.Vector3( j, 0,   size ) );
                               geo.vertices.push( new THREE.Vector3( j, 0, - size ) );

                               geo.vertices.push( new THREE.Vector3( size, 0,   j ) );
                               geo.vertices.push( new THREE.Vector3( -size, 0,  j ) );
                               geo.vertices.push( new THREE.Vector3( size, 0,   -j ) );
                               geo.vertices.push( new THREE.Vector3( -size, 0, -j ) );
                             }
                           }

                           return geo;
                         });

  var line_material =
    UIResources().cached('grid_material',
      function(i) {
        return new THREE.LineBasicMaterial( { color: 0xcccccc,
                                              opacity: 0.4 } );
      })

  var grid_line =
    UIResources().cached('grid_line',
      function(i){
        return new THREE.Line(line_geometry, line_material,
                              THREE.LinePieces );
      });
  this.components.push(grid_line);
}

/* Instantiate and return a new SelectBox
 */
function SelectBox(args){
  $.extend(this, new UIComponent(args));

  this.div_id = '#canvas_select_box';

  this.canvas = args['canvas'];

  /* disable explicity show / hide
   */
  this.show = this.hide = this.toggle = function(){};
  

  /* start showing the select box at the specified coords
   */
  this.start_showing = function(x,y){
    this.dx = x; this.dy = y;
    this.component().show();
  }

  /* stop showing and hide the select box
   */
  this.stop_showing = function(){
    var comp = this.component();
    comp.css('left', 0);
    comp.css('top',  0);
    comp.css('min-width',  0);
    comp.css('min-height', 0);
    comp.hide();
  }

  /* update the select box
   */
  this.update_area = function(x,y){
    var comp = this.component();
    if(!comp.is(":visible")) return;
    var tlx = comp.css('left');
    var tly = comp.css('top');
    var brx = comp.css('left') + comp.css('min-width');
    var bry = comp.css('top')  + comp.css('min-height');

    var downX = this.dx; var downY = this.dy;
    var currX = x; var currY = y;

    if(currX < downX){ tlx = currX; brx = downX; }
    else             { tlx = downX; brx = currX; }

    if(currY < downY){ tly = currY; bry = downY; }
    else             { tly = downY; bry = currY; }

    var width  = brx - tlx;
    var height = bry - tly;

    var left = this.canvas.component().position().left + tlx;
    var top  = this.canvas.component().position().top + tly;

    this.component().css('left', left);
    this.component().css('top',   top);
    this.component().css('min-width',  width);
    this.component().css('min-height', height);
  }

  this.on('mousemove', function(sb, e){
    var x = e.pageX - this.canvas.component().offset().left;
    var y = e.pageY - this.canvas.component().offset().top;
    this.update_area.apply(this, [x, y])
  });

  this.on('mousedown', function(sb, e){
    var x = e.pageX - this.canvas.component().offset().left;
    var y = e.pageY - this.canvas.component().offset().top;
    this.start_showing.apply(this, [x, y]);
  });

  this.on('mouseup', function(sb, e){
    this.stop_showing.apply(this);
  });
}

