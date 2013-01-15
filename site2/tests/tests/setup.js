$(document).ready(function(){
  function before_all(details){
    // login user
    var user = new JRObject("Users::User", {id : 'mmorsi', password: 'isromm'});
    $omega_session.login_user(user);

    // load some serverside data
    OmegaQuery.system_with_name('Athena', null);
  }

  function before_each(details){
    // logout user
    $omega_session.logout_user();
  
    // login user
    var user = new JRObject("Users::User", {id : 'mmorsi', password: 'isromm'});
    $omega_session.login_user(user);
  }
  
  QUnit.moduleStart(before_all);
  QUnit.testStart(before_each);
  //QUnit.testDone(after_each);
  //QUnit.moduleDone(after_all);
  
});
