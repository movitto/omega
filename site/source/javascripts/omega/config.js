/* Omega Javascript Config
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

$omega_config = {
  // uri & paths
  host              : 'localhost',
  prefix            :   '/womega',
  images_path       :   '/images',

  // users
  anon_user         :      'anon',
  anon_pass         :      'nona',
  recaptcha_enabled :        true,
  recaptcha_pub     : 'replace me',

  // ui
  //canvas_width      :         900,
  //canvas_height     :         400,

  // event tracking
  ship_movement     :          10,
  ship_rotation     :         0.1,
  planet_movement   :          50,

  // stats
  stats             : [['num_of', 'users'], ['most_entities', 10]],

  // gfx
  resources    : { 'mining'       : { 'material' : '/meshes/pirateghost/ghostmap_png.png',
                                      'geometry' : '/meshes/pirateghost/pirateghost.js',
                                      'scale'    : [20, 20, 20],
                                      'rotation' : [0, 1.57, 0]},
                   'corvette'     : { 'material' : '/meshes/transportshuttle/texture/transport_shuttle.png',
                                      'geometry' : '/meshes/transportshuttle/texture/TransportShuttle.js',
                                      'scale'    : [50, 50, 50],
                                      'rotation' : [0, 3.14, 0]},
                   'transport'    : { 'material' : '/meshes/eris/shipCompleteMap.jpg',
                                      'geometry' : '/meshes/eris/eris.js',
                                      'scale'    : [20, 20, 20],
                                      'rotation' : [1.57, 0, 0]},
                   'destroyer'    : { 'material' : '/meshes/monera_smuggler/The Model/morena_map-smuggler.png',
                                      'geometry' : '/meshes/monera_smuggler/The Model/monera_smuggler.js',
                                      'scale'    : [20, 20, 20] ,
                                      'rotation' : [-1.57, 0, -1.57] },
                   'solar_system' : { 'material' : '/solar_system.png'},
                   'star'         : { 'material' : '/textures/greensun.jpg'},
                   'jump_gate'    : { 'material' : '/meshes/wormhole_generator/generatormap.jpg',
                                      'geometry' : '/meshes/wormhole_generator/wormhole_generator.js',
                                      'scale'    : [50, 50, 50],
                                      'rotation' : [-1.57, 0, 0],
                                      'offset'   : [-150, 0, 0]},
                   'planet0'      : { 'material' : '/textures/planet0.png' },
                   'planet1'      : { 'material' : '/textures/planet1.png' },
                   'planet2'      : { 'material' : '/textures/planet2.png' },
                   'planet3'      : { 'material' : '/textures/planet3.png' },
                   'planet4'      : { 'material' : '/textures/planet4.png' },
                   'asteroid'     : { 'geometry' : '/meshes/asteroids1.js',
                                      'scale'    : [50, 20, 100] },
                   'manufacturing' : { 'material' : '/meshes/research.png',
                                       'geometry' : '/meshes/research.js',
                                       'scale'    : [20, 20, 20] }}

}
