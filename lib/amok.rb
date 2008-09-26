# Amok -- a compact mock library

# Copyright (C) 2008 Christian Neukirchen <purl.org/net/chneukirchen>
#
# Amok is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

class Amok
  VERSION = '0.1'

  attr_reader :obj

  class Failed < RuntimeError
    attr_accessor :errors
  end

  def self.with(obj)
    mock = new(obj)
    yield obj, mock
    
    unless mock.successful?
      ex = Failed.new(mock.errors.join("  "))
      ex.errors = mock.errors.dup
      raise ex
    end
  end

  def self.make(hash, &block)
    a = new(Object.new, &block)
    hash.each { |key, value| a.on(key) { value } }
    a.obj
  end

  def initialize(obj, &block)
    @obj = obj
    @called = {}
    instance_eval(&block)  if block
  end

  def on(method=nil, args=nil, n=nil, &block)
    return NiceProxy.new(self, n)  unless method || block

    called = @called
    id = [method, args]
    called[id] = n
    previous = @obj.method(method)  rescue nil

    @obj.extend Module.new { define_method(method, &block) }  if block
    @obj.extend Module.new {
      define_method(method) { |*actual_args|
        if args.nil? || args == actual_args
          case called[id]
          when Numeric;  called[id] -= 1
          when false;    called[id] = true
          end
          super
        else
          # This loses the block being passed due to limitations in 1.8.
          (block && previous) ? previous.call(*actual_args) : super
        end
      }
    }
  end

  def need(method=nil, args=nil, n=false, &block)
    unless block
      case method
      when nil;        NiceProxy.new(self, n)        # mock.need.foo
      when Numeric;    NiceProxy.new(self, method)   # mock.need(3).foo
      end
    else
      on(method, args, n, &block)
    end
  end

  def never(method=nil, args=nil)
    return NiceProxy.new(self, 0)  if !method
    on(method, args, 0) {
      # should we raise here?
    }
  end

  def errors
    @called.reject { |k, v|
      v == 0 ||                 # run the right number of times
      v == true ||              # run at all
      v == nil                  # run? who cares?
    }.map { |(m, a), v|
      msg = m.to_s
      msg << "(#{a.map { |x| x.inspect }.join(", ")})"  if a
      if v == false
        msg << " was not called."
      else
        msg << " was called #{v.abs} times #{v < 0 ? "too often" : "too few"}."
      end
    }
  end

  def successful?
    errors.empty?
  end

  class NiceProxy
    instance_methods.each { |name|
      undef_method name  unless name =~ /^__|^instance_eval$/
    }

    def initialize(obj, n=nil)
      @obj, @n = obj, n
    end
    
    def method_missing(name, *args, &block)
      args = nil  if args.empty?   # allow any arguments when none are mentioned
      @obj.on(name, args, @n, &block)
      self
    end
  end
end
