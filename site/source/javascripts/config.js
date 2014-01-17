/* Omega Javascript Config
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

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
  recaptcha_pub     : 'change me',

  // ui
  //canvas_width      :         900,
  //canvas_height     :         400,
  cam : {position : [2000, 3000, 3000],
         target   : [0,    0,    0]},

  // event tracking
  ship_movement     :          10,
  ship_rotation     :        0.01,

  //movement
  movement_offset   : {min : 50, max: 100},

  // stats
  stats             : [['num_of', 'users'], ['users_with_most', 'entities', 10]],

  // gfx
  resources    : {
    'solar_system' : { 'material' : '/solar_system.png'},
    'star'         : { 'texture'  : '/textures/sun.jpg' },
    'jump_gate'    : { 'material' : '/meshes/wormhole_generator/generatormap.jpg',
                       'geometry' : '/meshes/wormhole_generator/wormhole_generator.json',
                       'scale'    : [50, 50, 50],
                       'rotation' : [1.57, 0, 0],
                       'offset'   : [-130, 0, 0]},
    'planet0'      : { 'material' : '/textures/planet0.png' },
    'planet1'      : { 'material' : '/textures/planet1.png' },
    'planet2'      : { 'material' : '/textures/planet2.png' },
    'planet3'      : { 'material' : '/textures/planet3.png' },
    'planet4'      : { 'material' : '/textures/planet4.png' },
    'asteroid'     : { 'material' : '/textures/asteroid01.png',
                       'geometry' : '/meshes/asteroids1.json',
                       'scale'    : [90, 90, 40],
                       'rotation' : [1.57,3.14,0]},
    'ships'        : {
      'mining'       : { 'material' : '/textures/hull.png',
                         'geometry' : '/meshes/Agasicles/agasicles.json',
                         'scale'    : [5, 5, 5],
                         'rotation' : [0, 0, 0],
                         'trails'   : [[0,-5,-23]],
                         'lamps'    : [[5, 0x0000ff, [0,-5,3]],
                                       [3, 0x0000ff, [0,-7,25]],
                                       [3, 0x0000ff, [0,-9,-19]]]},
      'corvette'     : { 'material' : '/textures/hull.png',
                         'geometry' : '/meshes/Sickle/sickle.json',
                         'scale'    : [5, 5, 5],
                         'rotation' : [0, 0, 0],
                         'trails'   : [[10,0,-7], [-10,0,-7]],
                         'lamps'    : [[1, 0x0000ff, [0,  2, 41]],
                                       [2, 0x0000ff, [0,  4, 14]],
                                       [2, 0x0000ff, [0, -2, -9]]]},
      'transport'    : { 'material' : '/textures/AeraHull.png',
                         'geometry' : '/meshes/Agesipolis/agesipolis.json',
                         'scale'    : [5, 5, 5],
                         'rotation' : [0, 0, 0]},
      'destroyer'    : { 'material' : '/textures/AeraHull.png',
                         'geometry' : '/meshes/Leonidas/yavok.json',
                         'scale'    : [2, 2, 2] },

    },

    'stations'      : {
      'manufacturing' : { 'material' : '/meshes/research1.png',
                          'geometry' : '/meshes/research.json',
                          'scale'    : [7, 7, 7],
                          'lamps' : [[5, 0x0000ff, [0,   25, 0]],
                                     [5, 0x0000ff, [0, -175, 0]]]}}
  },

  audio : {
    'click'        : {'src' : 'effects_click_wav'},
    'construction' : {'src' : 'effects_construct_wav'}
  }
};
