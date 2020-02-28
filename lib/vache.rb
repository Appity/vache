require 'vache/version'

class Vache
  # == Constants ============================================================

  TTL_DEFAULT_DEFAULT = 300.0 # seconds

  # == Extensions ===========================================================

  include Enumerable
  
  # == Properties ===========================================================

  attr_accessor :default
  attr_accessor :default_proc
  attr_reader :ttl_default
    
  # == Class Methods ========================================================

  def self.[](contents)
    # ...
  end
  
  # == Instance Methods =====================================================

  def initialize(default = nil, ttl_default: nil, &default_proc)
    @ttl_default = ttl_default&.to_f || TTL_DEFAULT_DEFAULT
    @default = default
    @default_proc = default_proc

    @entries = { }
  end

  def ttl_default=(ttl)
    @ttl_default = ttl&.to_f || TTL_DEFAULT_DEFAULT
  end

  def expire(key, ttl: nil, expires_at: nil)
    expires_at ||= Time.now + (ttl || TTL_DEFAULT_DEFAULT)

    if (entry = @entries[key])
      entry[0] = expires_at
    end
  end

  def expires?(key)
    e, _v = @entries[key]

    e
  end

  def expire_clear!
    now = Time.now

    @entries.delete_if do |k, (e, _v)|
      e <= now
    end

    nil
  end

  def [](key)
    expires_at, value = @entries[key]

    # Expiring in the future means it's safe to return the value now
    return value if (expires_at&.send(:>, Time.now))

    # An expired key needs to be cleared out
    @entries.delete(key) if (expires_at)

    # The entry has expired, but without a default proc nothing will happen
    return @default unless (@default_proc)

    # The default proc may assign one or more keys, so it's necessary
    # to re-fetch after assignment to see what got set.
    @default_proc.call(self, key)

    _expire, value = @entries[key]

    value
  end
  alias_method :key, :[]
  
  def []=(key, value)
    @entries[key] = [ Time.now + @ttl_default, value ]
  end

  def any?
    self.expire_clear!

    @entries.any?
  end

  def assoc(key)
    expires_at, value = @entries[key]

    # Expiring in the future means it's safe to return the value now
    return [ key, value ] if (expires_at&.send(:>, Time.now))

    # An expired key needs to be cleared out
    @entries.delete(key) if (expires_at)

    nil
  end
  
  def clear
    @entries.clear
  end

  def dig(key, *args)
    self[key]&.dig(*args)
  end
  
  def each
    now = Time.now
    
    if (block_given?)
      @entries.each do |k, (e, v)|
        next if (e <= now)
        
        yield [ k, v ]
      end

      self
    else
      Enumerator.new do |y|
        @entries.each do |k, (e, v)|
          next if (e <= now)
          
          y << [ k, v ]
        end
      end
    end
  end

  def empty?
    !self.any?
  end

  def eql?(hash)
    case (hash)
    when Vache
      self.to_h == hash.to_h
    else
      self.to_h == hash
    end
  end
  alias_method :==, :eql?
  
  def fetch(key, default = nil, &block)
    expires_at, value = @entries[key]

    # No expiration time means there's no entry
    return value if (expires_at&.send(:>, Time.now))

    # An expired key needs to be cleared out
    if (expires_at)
      @entries.delete(key)
    end

    return default if (default)

    return block.call(key) if (block_given?)

    raise KeyError, "key not found: #{key.inspect}"
  end

  def fetch_values(*keys, &block)
    keys.map do |key|
      fetch(key, &block)
    end
  end

  def include?(key)
    expires_at, _value = @entries[key]

    !!(expires_at and expires_at > Time.now)
  end
  alias_method :has_key?, :include?
  alias_method :key?, :include?
  alias_method :member?, :include?

  def keys
    self.expire_clear!

    @entries.keys
  end

  def length
    self.expire_clear!

    @entries.length
  end
  alias_method :size, :length

  def merge(hash)
    case (hash)
    when Vache
      @entries
    when Hash
      merged = Vache.new(@default, ttl_default: @ttl_default, &@default_proc)

      hash.each do |k, v|
        merged[k] = v
      end
    else
      # ...
    end
  end

  def store(key, value, ttl: nil, expires_at: nil)
    @entries[key] = [
      expires_at || (Time.now + (ttl || @ttl_default)),
      value
    ]
  end

  def to_a
    now = Time.now
    
    @entries.each_with_object([ ]) do |(k, (e, v)), a|
      next unless (e > now)

      a << [ k, v ]
    end
  end

  def to_h
    now = Time.now
  
    @entries.each_with_object({ }) do |(k, (e, v)), h|
      next unless (e > now)

      h[k] = v
    end
  end

  def values
    self.expire_clear!

    @entries.values.map do |_e, v|
      v
    end
  end

  # FIX: Map these methods as well.
  # any?
  # each
  # each_key
  # each_pair
  # each_value
  # eql?
  # filter
  # hash
  # keys
  # transform_keys
  # transform_values
  # to_a
  # to_h
  # values

  def expiration_to_a
    @entries.to_a
  end

  def expiration_to_h
    @entries
  end
end
