class ParallelProcessor
  attr_accessor :results

  def initialize(objects, opts = {}, &builder)
    @builders_count = (
      opts[:jobs] ||
      run_command("/usr/sbin/sysctl -n machdep.cpu.thread_count") ||
      run_command("nproc")
    ).to_i
    @builders_count = 1 if @builders_count < 1

    @objects = objects
    @builders = []
    @builders_count.times do |builder_i|
      queue = []
      th = Thread.new do
        sleep
        objs = []
        while arg = queue.shift
          objs << builder.call(arg, builder_i)
        end
        queue.concat(objs)
      end
      @builders << [queue, th]
    end
  end

  def run
    builder_i = 0
    @objects.each do |object|
      @builders[builder_i][0] << object
      builder_i += 1
      builder_i = 0 if builder_i == @builders_count
    end

    # Start build.
    @builders.each do |queue, th|
      sleep 0.01 while th.status != 'sleep'
      th.wakeup
    end
    @builders.each { |queue, th| th.join }

    objs = []
    builder_i = 0
    @objects.count.times do
      objs << @builders[builder_i][0].shift
      builder_i += 1
      builder_i = 0 if builder_i == @builders_count
    end
    @results = objs
  end

  private
  def run_command(*args)
    require 'tempfile'
    out = Tempfile.new('tty-screen')
    result = system(*args, out: out.path)
    return if result.nil?
    out.rewind
    out.read
  rescue IOError, SystemCallError
  ensure
    out.close if out
  end
end
