require 'yaml'

module RubyDig
  def dig(key, *rest)
    if value = (self[key] rescue nil)
      if rest.empty?
        value
      elsif value.respond_to?(:dig)
    value.dig(*rest)
      end
    end
  end
end

if RUBY_VERSION < '2.3'
  Array.send(:include, RubyDig)
  Hash.send(:include, RubyDig)
end

class Settings
  def self.load(path)
    @config = YAML.load(File.read(File.expand_path('./config.yml')))
  end

  def self.method_missing(m, *args, &block)
    @config.dig(m.to_s) || super(m, *args, &block)
  end
end
