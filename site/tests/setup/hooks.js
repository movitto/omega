/// Omega JS Test Hooks

//////////////////////////////// test hooks

function before_all(details){
  /// clear cookies
  /// FIXME XXX for some reason cookie removal isn't working in this content
  /// so if cookies pre-exist some tests may fail
  Omega.Session.prototype.clear_cookies();

  Omega.Test.disable_dialogs();
}

function before_module(details){
}

function before_each(details){
  Omega.UI.Loader.clear_universe();
}

function after_each(details){
}

function after_module(details){
}

function after_all(details){
  /// clear cookies
  Omega.Session.prototype.clear_cookies();

  /// clear entity gfx
  Omega.UI.CanvasEntityGfx.__loaded_tracker   = {};
  Omega.UI.CanvasEntityGfx.__resource_tracker = {};
}

QUnit.begin(before_all);
QUnit.moduleStart(before_module);
QUnit.testStart(before_each);
QUnit.testDone(after_each);
QUnit.moduleDone(after_module);
QUnit.done(after_all);
