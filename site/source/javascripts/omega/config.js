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
  canvas_width      :         900,
  canvas_height     :         400,

  // event tracking
  ship_movement     :          10,
  ship_rotation     :         0.1,
  planet_movement   :          50

  // stats
  stats             : [['num_of', 'users'], ['most_entities', 10]],
}
