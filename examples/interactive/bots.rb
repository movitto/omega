#!/usr/bin/ruby

detach = false

bot   = File.join(File.dirname(__FILE__), 'bot.rb')
users = ['Anubis', 'Aten', 'Horus', 'Imhotep', 'Ptah']
users.each { |user|
  (pid = fork) ?
    (detach ? Process.detach(pid) : nil) :
    exec("/usr/bin/ruby -Ilib #{bot} #{user}")
}

Process.waitall unless detach
