/* Omega JS Ship Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipGfxLoader = {
  /// template mesh, mesh, and particle texture
  async_gfx : 3,

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded(this.type)) return;
    Omega.Ship.gfx    = Omega.Ship.gfx || {};

    var gfx           =      {};
    gfx.hp_bar        =      new Omega.ShipHpBar();
    gfx.highlight     =      new Omega.ShipHighlightEffects();
    gfx.mesh_material =      new Omega.ShipMeshMaterial({config: config,
                                                           type: this.type,
                                                       event_cb: event_cb});
    gfx.lamps         =             new Omega.ShipLamps({config: config,
                                                           type: this.type});
    gfx.trails        =            new Omega.ShipTrails({config: config,
                                                           type: this.type,
                                                       event_cb: event_cb});
    gfx.visited_route =      new Omega.ShipVisitedRoute({config: config,
                                                       event_cb: event_cb});
    gfx.attack_vector =      new Omega.ShipAttackVector({config: config,
                                                       event_cb: event_cb});
    gfx.artillery     =         new Omega.ShipArtillery({config: config,
                                                       event_cb: event_cb});
    gfx.missiles      =          new Omega.ShipMissiles({config: config,
                                                       event_cb: event_cb});
    gfx.mining_vector =      new Omega.ShipMiningVector({config: config,
                                                       event_cb: event_cb});
    gfx.trajectory1   =         new Omega.ShipTrajectory({color: 0x0000FF,
                                                      direction: 'primary'});
    gfx.trajectory2   =         new Omega.ShipTrajectory({color: 0x00FF00,
                                                      direction: 'secondary'});
    gfx.destruction   = new Omega.ShipDestructionEffect({config: config,
                                                       event_cb: event_cb});
    gfx.explosions    =   new Omega.ShipExplosionEffect({config: config,
                                                       event_cb: event_cb});
    gfx.smoke         =       new Omega.ShipSmokeEffect({config: config,
                                                       event_cb: event_cb});
    gfx.docking_audio     = new Omega.ShipDockingAudioEffect({config: config});
    gfx.mining_audio      = new Omega.ShipMiningAudioEffect({config: config});
    gfx.destruction_audio = new Omega.ShipDestructionAudioEffect({config: config});
    gfx.mining_completed_audio = new Omega.ShipMiningCompletedAudioEffect({config: config});
    gfx.combat_audio = new Omega.ShipCombatAudioEffect({config: config});
    gfx.movement_audio = new Omega.ShipMovementAudioEffect({config: config});
    Omega.Ship.gfx[this.type] = gfx;

    Omega.ShipMesh.load_template(config, this.type, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });

    this._loaded_gfx(this.type);
  }
};
