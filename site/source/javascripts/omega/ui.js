/* Omega Javascript Interface
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/jquery-ui-1.10.2.min"
//= require "vendor/mousehold"
//= require "vendor/utf8_encode"
//= require "vendor/md5"
//= require "vendor/jquery.timer"

/// three.js and deps
//= require "vendor/three-r58"
//= require 'vendor/three/EffectComposer'
//= require 'vendor/three/RenderPass'
//= require 'vendor/three/ShaderPass'
//= require 'vendor/three/MaskPass'
//= require 'vendor/three/CopyShader'
//= require 'vendor/three/ConvolutionShader.js'
//= require 'vendor/three/BloomPass'
//= require 'vendor/three/FilmShader'
//= require 'vendor/three/FilmPass'

/* UI Resources registry.
 *
 * Implements singleton pattern
 */
function UIResources(){
  if ( UIResources._singletonInstance )
    return UIResources._singletonInstance;
  var _this = {};
  UIResources._singletonInstance = _this;

  $.extend(_this, new Registry());
  $.extend(_this, new EventTracker());

  // to render textures
  var texture_placeholder = document.createElement( 'canvas' );

  // to load mesh geometries
  if(window.THREE != undefined) var loader = new THREE.JSONLoader();

  /* Path to images directory
   */
  _this.images_path = $omega_config['prefix'] + $omega_config['images_path'];

  /* Load a remote texture resource from the specified path
   */
  _this.load_texture = function(path){
    // TODO cache path locally ?
    return THREE.ImageUtils.loadTexture(path, {}, function(t){
      _this.raise_event('texture_loaded', t)
    });
  }

  /* Loads a textured material from the specified path
   */
  _this.load_texture_material = function(path){
    var texture  = new THREE.Texture( texture_placeholder );
    var material = new THREE.MeshBasicMaterial( { map: texture, overdraw: true } );

    var image = new Image();
    image.onload = function () {
      texture.needsUpdate = true;
      material.map.image = this;
      _this.raise_event('texture_loaded', _this)
    };
    image.src = path;
    return material;
  }

  /* Loads a texture cube from the materials at the specified path
   */
  _this.load_texture_cube = function(paths){
    return THREE.ImageUtils.loadTextureCube(paths, {}, function(t){
      _this.raise_event('texture_loaded', t);
    });
  }

  /* Loads specified json
   */
  _this.load_json = function(path, cb){
    var evnt = 'json_'+path+'_loaded';
    var loading = false;
    if(_this.callbacks[evnt] && _this.callbacks[evnt].length > 0) loading = true;
    _this.on(evnt, function(r, j){ cb.apply(null, [j]); });
    if(loading) return;

    loader.load(path, function(j){
      _this.raise_event(evnt, j);
      _this.clear_callbacks(evnt);
    });
  }

  /* Load a remote mesh geometry resource from the specified path
   * and invoke callback when it is loaded
   */
  _this.load_geometry = function(path, cb){
    var evnt = 'geometry_'+path+'_loaded';
    var loading = false;
    if(_this.callbacks[evnt] && _this.callbacks[evnt].length > 0) loading = true;
    if(cb) _this.on(evnt, function(r, g){ cb.apply(null, [g]); })
    if(loading) return;

    loader.load(path, function(geometry){
      _this.raise_event(evnt, geometry);
      _this.raise_event('geometry_loaded', geometry);
      _this.clear_callbacks(evnt);
    }, UIResources().images_path + '/meshes');
  }

  return _this;
}

/* UI component base class.
 *
 * Subclasses should set 'id' attribut to css id of div corresponding
 * to component. Setting to null inidicates this component has no div
 *
 * Subclasses may define the 'close_control_id' to reference
 * a page element which when clicked should hide the
 * component on the page
 *
 * Subclasses may define the 'toggle_control_id' to reference
 * a page element which when clicked will toggle the
 * component on the page
 */
function UIComponent(args){
  $.extend(this, new EventTracker());

  this.subcomponents = [];

  /* Override callback registration to track page events
   */
  this.old_on = this.on;
  this.on = function(cb_id, cb){
    this.old_on(cb_id, cb);

    var comp = this;
    if(cb_id == 'resize'){
      this.component().resizable();
      this.component().resize(function(e){
        comp.raise_event('resize', e);
      });

    }else if(cb_id == "click"){
      this.component().live('click', function(e){
        comp.raise_event('click', e);
      });

    }else if(cb_id == "mouseenter"){
      this.component().live('mouseenter', function(e){
        comp.raise_event('mouseenter', e);
      });

    }else if(cb_id == "mouseleave"){
      this.component().live('mouseleave', function(e){
        comp.raise_event('mouseleave', e);
      });

    }else if(cb_id == "mousemove"){
      this.component().live('mousemove', function(e){
        comp.raise_event('mousemove', e);
      });

    }else if(cb_id == "mousedown"){
      this.component().live('mousedown', function(e){
        comp.raise_event('mousedown', e);
      });

    }else if(cb_id == "mouseup"){
      this.component().live('mouseup', function(e){
        comp.raise_event('mouseup', e);
      });
    }

  }

  /* Return the page component corresponding to this entity
   */
  this.component = function(){
    if(this._component == null)
      this._component = $(this.div_id)
    return this._component;
  }

  /* Append content to the component
   */
  this.append = function(content){
    this.component().append(content);
  }

  /* Return the page component corresponding to the close control
   */
  this.close_control = function(){
    if(this._close_control == null)
      this._close_control = $(this.close_control_id)
    return this._close_control; 
  }

  /* Return the page component corresponding to the toggle control
   */
  var toggled = false;
  this.toggle_control = function(){
    if(this._toggle_control == null)
      this._toggle_control = $(this.toggle_control_id)
    return this._toggle_control;
  }

  /* Show the omega component
   */
  this.show = function(){
    this.toggled = true;
    if(this.toggle_control())
      this.toggle_control().attr('checked', true);

    if(this.component())
      this.component().show();
    for(var cmp = 0; cmp < this.subcomponents.length; cmp++)
      this.subcomponents[cmp].show();
    this.raise_event('show');
  }

  /* Hide the component
   */
  this.hide = function(){
    this.toggled = false;
    if(this.toggle_control())
      this.toggle_control().attr('checked', false);

    if(this.component())
      this.component().hide();
    for(var cmp = 0; cmp < this.subcomponents.length; cmp++)
      this.subcomponents[cmp].hide();
    this.raise_event('hide');
  }

  /* Return component visibility
   */
  this.visible = function(){
    return this.component().is(':visible');
  }

  /* Toggle showing/hiding the component in on the page based
   * on checked attribute of the toggle_control input
   */
  this.toggle = function(){
    this.toggled = !this.toggled;

    if(this.toggled)
      this.show();
    else
      this.hide();

    this.raise_event('toggle');
  }

  /* Set component size
   */
  this.set_size = function(w, h){
    // resize to specified width/height
    this.component().height(h);
    this.component().width(w);
    this.component().trigger('resize');
  }

  /* Return representation of a page click event's coordinates in
   * relation to the component's coordinate system, with
   * the origin (0,0) being the component's center.
   *
   * Pass x,y position of the click event relative to screen/window.
   * The value returned will be the in the domain of [[-1,1],[-1,1]]
   * indicating the percentage of the components coordinate system
   * at which the click occured
   */
  this.click_coords = function(x,y){
    var nx = Math.floor(x-this.component().offset().left);
    var ny = Math.floor(y-this.component().offset().top);
    nx =   nx / this.component().width() * 2 - 1;
    ny = - ny / this.component().height() * 2 + 1;
    return [nx, ny];
  }


  /* Lock component in place. Client should specify sides to lock
   */
  this.lock = function(sides){
    var comp = this.component();
    if(!comp) return;
    comp.css({position: 'absolute'});
    if(typeof sides === "str")
      sides = [sides];

    for(var side = 0; side < sides.length; side++){
      if(sides[side] == 'top')
        comp.css({top : comp.position().top});
      else if(sides[side] == 'left')
        comp.css({left: comp.position().left});
      else if(sides[side] == 'right')
        comp.css({right: $(document).width() - comp.offset().left - comp.width()});
        //comp.css({right: comp.position().right});
      //else if(sides[side] == 'bottom')
    }
  }

  /* Wire up the controls to the page
   */
  this.wire_up = function(){
    this.close_control().die();
    this.toggle_control().die();

    var comp = this;
    this.close_control().live('click',  function(e) { comp.hide();   });
    this.toggle_control().live('click', function(e) { comp.toggle(); })

    // XXX ensure clicks don't propagate to canvas
    this.close_control().on('mousedown',  stop_prop);
    this.toggle_control().on('mousedown',  stop_prop);

    this.toggled = true;
    this.toggle();
  }
}

/* UI List Component
 *
 * Imposes no additional restrictions on subclasses
 */
function UIListComponent(args){
  $.extend(this, new UIComponent(args));

  /* html element to wrap items in
   */
  this.item_wrapper = 'span';

  /* Each item should be an object containing
   * 'item', 'id', and 'text' attributes
   */
  this.items = [];

  /* Function used to sort list before refreshing
   */
  this.sort = function(a,b){ return -1; };

  /* Clear items in the list
   */
  this.clear = function(){
    this.items = [];
  }

  /* Add item to this list
   */
  this.add_item = function(item){
    if($.isArray(item)){
      for(var i = 0; i < item.length; i++)
        this.add_item(item[i]);
      return;
    }

    var overwrote = false
    for(var i = 0; i < this.items.length; i++){
      if(this.items[i].id == item.id){
        this.items[i] = item;
        overwrote = true;
        break;
      }
    }
    if(!overwrote){
      this.items.push(item);

      // wire up clicked handler
      // XXX probably should go into 'on' function
      // as in UIComponent callbacks, but this is
      // simple/clean/works for now
      var comp = this;
      $('#' + item.id).live('click', function(e){
        comp.raise_event('click_item', item, e);
      });
    }

    this.refresh();
  }

  this.refresh = function(){
    if(!this.component()) return;
    this.component().html('');
    var text = '';
    this.items.sort(this.sort);
    for(var i = 0; i < this.items.length; i++)
      text += '<' +this.item_wrapper+ ' id="' + this.items[i].id + '">' +
              this.items[i].text + '</' +this.item_wrapper + '>';
    this.component().html(text);
  }

  /* Add text to the list w/ interally generated id
   */
  this.add_text = function(text){
    if($.isArray(text)){
      for(var i = 0; i < text.length; i++)
        this.add_text(text[i]);
      return;
    }

    if(!this.id_inc) this.id_inc = 0;
    this.id_inc += 1;

    var item = {id : this.id_inc, text : text, item : null};
    this.add_item(item);
  };
}
