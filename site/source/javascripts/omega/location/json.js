/* Omega Location JSON Operations
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationJSON = {
  /// Return location in JSON format
  toJSON : function(){
    return {json_class : this.json_class,
            id : this.id,
            x : this.x,
            y : this.y,
            z : this.z,
            orientation_x : this.orientation_x,
            orientation_y : this.orientation_y,
            orientation_z : this.orientation_z,
            parent_id : this.parent_id,
            movement_strategy : this.movement_strategy};
  }
};
