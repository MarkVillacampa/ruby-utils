module LoggerClassMethods
  module Colorizer
    extend self
    String.send(:include, self)

    %w[gray red green yellow blue purple cyan white].each_with_index do |color, i|
      define_method color do |str=self|
        "\e[1;#{30+i}m#{str}\e[0m"
      end

      define_method "#{color}ish" do |str=self|
        "\e[0;#{30+i}m#{str}\e[0m"
      end
    end

    alias black grayish
    alias pale  whiteish
  end

  FLAGS = {
    :error    => (1<<0), # 0...0001
    :warn     => (1<<1), # 0...0010
    :info     => (1<<2), # 0...0100
    :verbose  => (1<<3), # 0...1000
    :debug    => (1<<3)  # 0...1000
  }.freeze

  LEVELS = {
    :off      => 0,
    :error    => FLAGS[:error],
    :warn     => FLAGS[:error] | FLAGS[:warn],
    :info     => FLAGS[:error] | FLAGS[:warn] | FLAGS[:info],
    :verbose  => FLAGS[:error] | FLAGS[:warn] | FLAGS[:info] | FLAGS[:verbose],
    :debug    => FLAGS[:error] | FLAGS[:warn] | FLAGS[:info] | FLAGS[:verbose]
  }.freeze

  def level=(level)
    @level = level
  end

  def level
    @level
  end

  def async=(async)
    @async = async
  end

  def async
    @async
  end

  def error(message)
    __log(:error, Colorizer.red(message))
  end

  def warn(message)
    __log(:warn, Colorizer.yellow(message))
  end

  def info(message)
    __log(:info, Colorizer.white(message))
  end

  def debug(message)
    __log(:verbose, Colorizer.cyan(message))
  end
  alias verbose debug

  def logging?(flag)
    (LEVELS[level] & FLAGS[flag]) > 0
  end

  protected

  def __log(flag, message)
    return unless logging?(flag)
    raise ArgumentError, "flag must be one of #{FLAGS.keys}" unless FLAGS.keys.include?(flag)
    require 'thread'
    @print_mutex ||= Mutex.new
    # Because this method can be called concurrently, we don't want to mess any output.
    string = "[#{flag.to_s.upcase}] [#{Time.now.strftime('%Y-%m-%d %H:%M:%S.%3N')}] #{message}"
    @print_mutex.synchronize do
      puts string
    end
  end
end

class Log
  extend LoggerClassMethods
  @level = :info
end
