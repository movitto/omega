/* Omega Common Scene JS Routines
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// Omega Scene Effects
Omega.SceneEffects = {

  //// slowly move camera towards target
  transition_camera : function(canvas, tgt_pos, dist, cb) {
    var pos  = canvas.cam.position;
    var tgt_dist = tgt_pos.distance_from(pos.x, pos.y, pos.z);

    /// if camera on target, invoke cb & return
    if(tgt_dist < 100){
      if(cb) cb();
      return;
    }

    /// move camera
    var d = tgt_pos.direction_to(pos.x, pos.y, pos.z);
    pos.sub(new THREE.Vector3(d[0] * dist, d[1] * dist, d[2] * dist));
  }
}
