/* Omega Javascript Config
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// TODO move to top level javascripts/ dir

Omega.Config = {
  // uri & paths
  http_host         : 'localhost',
  http_path         : '/omega',
  ws_host           : 'localhost',
  ws_port           :  8080,

  url_prefix        :   '/womega',
  images_path       :   '/images',
  meshes_path       :   '/meshes',

  // users
  anon_user         :      'anon',
  anon_pass         :      'nona',
  recaptcha_enabled :        true,
  recaptcha_pub     : '6LflM9QSAAAAAHsPkhWc7OPrwV4_AYZfnhWh3e3n',

  // ui
  //canvas_width      :         900,
  //canvas_height     :         400,

  // event tracking
  ship_movement     :          10,
  ship_rotation     :        0.01,
  planet_movement   :          50,

  // stats
  stats             : [['num_of', 'users'], ['with_most', 'entities', 10]],

  // gfx
  resources    : { 'mining'       : { 'material' : '/meshes/pirateghost/ghostmap_png.png',
                                      'geometry' : '/meshes/pirateghost/pirateghost.json',
                                      'scale'    : [5, 5, 5],
                                      'rotation' : [0, 0, 0],
                                      'trails'   : [[19,2.5,-32.5],[-19,2.5,-32.5],[0,5,-55],[0,-2.5,-55]],
                                      'lamps'    : [[1, 0x0000ff, [0,16,-2]],
                                                    [2, 0x0000ff, [0,15,-16]],
                                                    [5, 0x0000ff, [0,0,54]],
                                                    [5, 0x0000ff, [0,-6,-48]]]},
                   'corvette'     : { 'material' : '/meshes/transportshuttle/texture/transport_shuttle.png',
                                      'geometry' : '/meshes/transportshuttle/texture/TransportShuttle.json',
                                      'scale'    : [20, 20, 20],
                                      'rotation' : [0, 0, 0],
                                      'trails'   : [[10,0,-37.5], [-10,0,-37.5]],
                                      'lamps'    : [[1, 0x0000ff, [0, -3, 41]],
                                                    [2, 0x0000ff, [0, 4, 14]],
                                                    [3, 0x0000ff, [0, -5, -27]]]},
                   'transport'    : { 'material' : '/meshes/eris/shipCompleteMap.jpg',
                                      'geometry' : '/meshes/eris/eris.json',
                                      'scale'    : [20, 20, 20],
                                      'rotation' : [1.57, 0, 0]},
                   'destroyer'    : { 'material' : '/meshes/monera_smuggler/The Model/morena_map-smuggler.png',
                                      'geometry' : '/meshes/monera_smuggler/The Model/monera_smuggler.json',
                                      'scale'    : [20, 20, 20] ,
                                      'rotation' : [-1.57, 0, -1.57] },
                   'solar_system' : { 'material' : '/solar_system.png'},
                   'star'         : { 'clouds'   : '/textures/lava/cloud.png',
                                      'lava'     : '/textures/lava/lavatile.jpg'},
                   'jump_gate'    : { 'material' : '/meshes/wormhole_generator/generatormap.jpg',
                                      'geometry' : '/meshes/wormhole_generator/wormhole_generator.json',
                                      'scale'    : [50, 50, 50],
                                      'rotation' : [1.57, 0, 0],
                                      'offset'   : [-150, 0, 0]},
                   'planet0'      : { 'material' : '/textures/planet0.png' },
                   'planet1'      : { 'material' : '/textures/planet1.png' },
                   'planet2'      : { 'material' : '/textures/planet2.png' },
                   'planet3'      : { 'material' : '/textures/planet3.png' },
                   'planet4'      : { 'material' : '/textures/planet4.png' },
                   'asteroid'     : { 'material' : '/textures/asteroid01.png',
                                      'geometry' : '/meshes/asteroids1.json',
                                      'scale'    : [90, 90, 40],
                                      'rotation' : [1.57,3.14,0]},
                   'manufacturing' : { 'material' : '/meshes/research.png',
                                       'geometry' : '/meshes/research.json',
                                       'scale'    : [7, 7, 7],
                                       'lamps' : [[5, 0x0000ff, [0,   25, 0]],
                                                  [5, 0x0000ff, [0, -175, 0]]]}}

};
