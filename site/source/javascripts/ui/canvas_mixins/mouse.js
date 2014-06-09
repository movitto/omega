/* Omega JS Canvas Mouse Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasMouseHandler = {
  wire_up_mouse : function(){
    var _this = this;
    this.canvas.off('mousedown mouseup mouseleave mouseout mousemove'); /// <- needed ?

    /// detect clicks dispatch to _canvas_clicked.
    /// mouseup / down must occur within 1/2 second
    /// to be registered as a click
    /// TODO drag-n-drop selection box
    var click_duration = 500, timestamp = null;
    this.canvas.mousedown(function(evnt){
      timestamp = new Date();
    });

    this.canvas.mouseup(function(evnt) {
      if(new Date() - timestamp < click_duration){
        timestamp = null;
        _this._canvas_clicked(evnt);
      }
    })

    /// when mouse leaves canvas, trigger up event
    this.canvas.on('mouseleave', function(){ /// XXX resulting in a mouseout event
      //_this.canvas.trigger('mouseup');
      var evnt = document.createEvent('MouseEvents');
      evnt.initMouseEvent('mouseup', 1, 1, window, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, null);
      _this.cam_controls.domElement.dispatchEvent(evnt);
    });

    this.canvas.on('mousemove', function(evnt){
      _this.mouse_x = evnt.clientX;
      _this.mouse_y = evnt.clientY;
    });
  },

  // Return the 2D screen coords mapped to 2D canvas coords
  _screen_coords_to_canvas : function(x, y){
    // map page coords to canvas scene coords
    var nx = Math.floor(x - this.canvas.offset().left);
    var ny = Math.floor(y - this.canvas.offset().top);
        nx =   nx / this.canvas.width()  * 2 - 1;
        ny = - ny / this.canvas.height() * 2 + 1;

    return [nx, ny];
  },

  // Return canvas picking ray from 2D screen coords
  _picking_ray : function(x, y){
    var xy = this._screen_coords_to_canvas(x, y);
    var cx = xy[0];
    var cy = xy[1];

    var projector = new THREE.Projector();
    return projector.pickingRay(new THREE.Vector3(cx, cy, 0.5), this.cam);
  },

  _canvas_clicked : function(evnt){
    var        ray = this._picking_ray(evnt.pageX, evnt.pageY);
    var intersects = ray.intersectObjects(this.scene.getDescendants());

    if(intersects.length > 0){
      var obj = intersects[0].object.omega_obj;
      var entity = obj ? obj.omega_entity : null;
      if(entity){
        switch (evnt.which){
          case 1: //Left click
            this._clicked_entity(entity);
            break;
          case 3: //Right click
            this._rclicked_entity(entity);
            break;
          case 4: //Middle click
            break;
        }
      }
    }
  },

  _detect_hover : function(){
    if(!this.mouse_x || !this.mouse_y) return;

    var        ray = this._picking_ray(this.mouse_x, this.mouse_y);
    var intersects = ray.intersectObjects(this.descendants());
    if(intersects.length > 0){
      var obj = intersects[0].object.omega_obj;
      var entity = obj ? obj.omega_entity : null;
      if(entity){
        var first_hover = this._hovered_entity != entity;
        this._hover_num = first_hover ? 1 : (this._hover_num + 1);
        this._hovered_entity = entity;
        this._hovered_over(entity, this._hover_num);

      }else if(this._hovered_entity){
        this._unhovered_over(this._hovered_entity);
        this._hover_num = 0;
        this._hovered_entity = null;
      }
    }
  },

  _clicked_entity : function(entity){
    if(entity.clicked_in) entity.clicked_in(this);
    if(entity.has_details) this.entity_container.show(entity);
    entity.dispatchEvent({type: 'click'});
  },

  _rclicked_entity : function(entity){
    var selected = this.entity_container.entity;
    if (selected) {
      if(selected.context_action) selected.context_action(entity, this.page);
      entity.dispatchEvent({type: 'rclick'});
    }
  },

  _hovered_over : function(entity, hover_num){
    if(entity.on_hover) entity.on_hover(this, hover_num);
    entity.dispatchEvent({type: 'hover'});
  },

  _unhovered_over : function(entity){
    if(entity.on_unhover) entity.on_unhover(this);
    entity.dispatchEvent({type: 'unhover'});
  }
}
