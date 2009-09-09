#
# $Id: semaphore.rb,v 1.2 2003/03/15 20:10:10 fukumoto Exp $
#
# Copied unmodified from:
#   http://www.imasy.or.jp/~fukumoto/ruby/semaphore.rb
# Originally licensed under The Ruby License:
#   http://raa.ruby-lang.org/project/semaphore/

class CountingSemaphore

  def initialize(initvalue = 0)
    @counter = initvalue
    @waiting_list = []
  end

  def wait
    Thread.critical = true
    if (@counter -= 1) < 0
      @waiting_list.push(Thread.current)
      Thread.stop
    end
    self
  ensure
    Thread.critical = false
  end

  def signal
    Thread.critical = true
    begin
      if (@counter += 1) <= 0
	t = @waiting_list.shift
	t.wakeup if t
      end
    rescue ThreadError
      retry
    end
    self
  ensure
    Thread.critical = false
  end

  alias down wait
  alias up signal
  alias P wait
  alias V signal

  def exclusive
    wait
    yield
  ensure
    signal
  end

  alias synchronize exclusive

end

Semaphore = CountingSemaphore
