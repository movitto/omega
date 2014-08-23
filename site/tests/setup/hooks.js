/// Omega JS Test Hooks

//////////////////////////////// test hooks

function before_all(details){
  /// clear cookies
  /// FIXME XXX for some reason cookie removal isn't working in this content
  /// so if cookies pre-exist some tests may fail
  Omega.Session.prototype.clear_cookies();

  Omega.Test.disable_dialogs();
}

function before_each(details){
  Omega.UI.Loader.clear_universe();
}

function after_each(details){
}

function after_all(details){
  /// clear cookies
  Omega.Session.prototype.clear_cookies();
}

QUnit.moduleStart(before_all);
QUnit.testStart(before_each);
QUnit.testDone(after_each);
QUnit.moduleDone(after_all);

