class Vache::Set
  # == Constants ============================================================
  
  # == Extensions ===========================================================
  
  # == Properties ===========================================================
  
  # == Class Methods ========================================================
  
  # == Instance Methods =====================================================
  
  def initialize(list = nil, ttl_default: nil)
    @ttl_default = ttl_default&.to_f || Vache::TTL_DEFAULT_DEFAULT
    @default = default
    @default_proc = default_proc

    @entries = { }
  end

  def ttl_default=(ttl)
    @ttl_default = ttl&.to_f || Vache::TTL_DEFAULT_DEFAULT
  end

  def expire(key, ttl: nil, expires_at: nil)
    expires_at ||= Time.now + (ttl || Vache::TTL_DEFAULT_DEFAULT)

    if (entry = @entries[key])
      entry[0] = expires_at
    end
  end

  def expires?(key)
    @entries[key]
  end

  def expire_clear!
    now = Time.now

    @entries.delete_if do |_k, e|
      e <= now
    end

    nil
  end

  def <<(key)
    @entries[key] = Time.now + @ttl_default
  end

  def any?
    self.expire_clear!

    @entries.any?
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

  def eql?(set)
    case (set)
    when Vache::Set
      self.to_h == hash.to_h
    else
      self.to_h == hash
    end
  end
  alias_method :==, :eql?
  
  def include?(key)
    expires_at = @entries[key]

    !!(expires_at and expires_at > Time.now)
  end
  alias_method :member?, :include?

  def to_a
    self.expire_clear!

    @entries.keys
  end

  def length
    self.expire_clear!

    @entries.length
  end
  alias_method :size, :length

  def merge(set)
    # ...
  end

  def store(key, ttl: nil, expires_at: nil)
    @entries[key] = expires_at || (Time.now + (ttl || @ttl_default))
  end

  def expiration_to_a
    @entries.to_a
  end

  def expiration_to_h
    @entries
  end
end
