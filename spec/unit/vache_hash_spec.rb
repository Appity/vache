RSpec.describe Vache::Hash do
  it 'can be initialized without arguments' do
    vache = Vache::Hash.new

    expect(vache).to_not be_any
    expect(vache).to be_empty
    expect(vache.length).to eq(0)
    expect(vache.size).to eq(0)

    expect(vache.default).to be(nil)
    expect(vache.default_proc).to be(nil)

    expect(vache).to eq({ })
    expect(vache.to_a).to eq([ ])
    expect(vache.to_h).to eq({ })
    expect(vache.each.to_a).to eq([ ])

    expect(vache[:a]).to be(nil)
    expect { vache.fetch(:a) }.to raise_exception(KeyError)

    expect(vache.expire_clear!).to be(nil)
  end

  it 'can be initialized with a default' do
    vache = Vache::Hash.new('default')

    expect(vache).to_not be_any
    expect(vache).to be_empty
    expect(vache.length).to eq(0)
    expect(vache.size).to eq(0)

    expect(vache.default).to eq('default')
    expect(vache.default_proc).to be(nil)
    expect(vache.ttl_default).to eq(300)

    expect(vache).to eq({ })

    expect(vache[:a]).to eq('default')
    expect { vache.fetch(:a) }.to raise_exception(KeyError)
  end

  it 'can be initialized with a default proc' do
    vache = Vache::Hash.new { |h, k| h[k] = k.to_s.upcase }

    expect(vache).to_not be_any
    expect(vache).to be_empty
    expect(vache.length).to eq(0)
    expect(vache.size).to eq(0)

    expect(vache.default).to be(nil)
    expect(vache.default_proc).to be_kind_of(Proc)
    expect(vache).to eq({ })

    expect { vache.fetch(:a) }.to raise_exception(KeyError)

    # Accessing a missing key through #[] will instantiate it if a default
    # proc has been assigned.
    expect(vache[:a]).to eq('A')
    expect(vache.fetch(:a)).to eq('A')
  end

  it 'can be initialized and later assigned a default proc' do
    vache = Vache::Hash.new
    
    expect { vache.fetch(:a) }.to raise_exception(KeyError)
    expect(vache[:a]).to be(nil)
    expect(vache.length).to eq(0)

    vache.default_proc = -> (h, k) { h[k] = k.to_s.upcase }

    expect(vache[:a]).to eq('A')
    expect(vache.fetch(:a)).to eq('A')
    expect(vache.length).to eq(1)

    expect(vache).to eq(a: 'A')
    expect(vache.to_a).to eq([ [ :a, 'A' ] ])
    expect(vache.to_h).to eq(a: 'A')
  end

  it 'can be initialized with a different TTL default' do
    vache = Vache::Hash.new(ttl_default: 1)

    expect(vache.ttl_default).to eq(1)
  end

  it 'can have a different TTL default assigned' do
    vache = Vache::Hash.new(ttl_default: 10)

    expect(vache.ttl_default).to eq(10)

    vache.ttl_default = 20

    expect(vache.ttl_default).to eq(20)

    vache.ttl_default = nil

    expect(vache.ttl_default).to eq(300)
  end

  describe 'can test for the presence of keys' do
    before do
      @vache = Vache::Hash.new do |h,k|
        h[k] = k.to_s.upcase
      end
      @vache[:a] = '@'
    end

    it 'with #[]' do
      expect(@vache[:a]).to eq('@')
      expect(@vache[:b]).to eq('B')
    end

    it 'with #fetch' do
      expect(@vache.fetch(:a)).to eq('@')
      expect { @vache.fetch(:b) }.to raise_exception(KeyError)
    end

    it 'with #assoc' do
      expect(@vache.assoc(:a)).to eq([ :a, '@' ])
      expect(@vache.assoc(:b)).to eq(nil)
    end

    it 'with #include?' do
      expect(@vache.include?(:a)).to eq(true)
      expect(@vache.include?(:b)).to eq(false)
    end

    it 'with #keys' do
      expect(@vache.keys).to include(:a)
      expect(@vache.keys).to_not include(:b)
    end
  end

  it 'can expire arbitrary keys with a TTL' do
    vache = Vache::Hash.new

    vache.store(:a, 'A')

    expect(vache.length).to eq(1)
    expect(vache[:a]).to eq('A')

    vache.expire(:a, ttl: 10)

    expect(vache.length).to eq(1)
    expect(vache[:a]).to eq('A')

    expect(vache.to_a).to eq([ [ :a, 'A' ] ])
    expect(vache.each.to_a).to eq([ [ :a, 'A' ] ])

    Timecop.freeze(Time.now + 11) do
      expect(vache[:a]).to eq(nil)
      expect(vache.length).to eq(0)
    end
  end

  it 'can expire arbitrary keys with at a particular time' do
    vache = Vache::Hash.new

    vache.store(:a, 'A')

    expect(vache.length).to eq(1)
    expect(vache[:a]).to eq('A')

    vache.expire(:a, expires_at: Time.now + 10)

    expect(vache.length).to eq(1)
    expect(vache[:a]).to eq('A')

    expect(vache.expire_clear!).to be(nil)

    expect(vache.length).to eq(1)
    expect(vache[:a]).to eq('A')

    Timecop.freeze(Time.now + 11) do
      expect(vache[:a]).to eq(nil)
      expect(vache.length).to eq(0)
    end
  end

  it 'will permit reassignment to keys that have expired' do
    vache = Vache::Hash.new

    vache.store(:a, 'A1', ttl: 10)
    vache.store(:b, 'B1', ttl: 15)

    vache[:a] ||= 'A2'

    expect(vache[:a]).to eq('A1')

    Timecop.freeze(Time.now + 11) do
      vache[:a] ||= 'A2'

      expect(vache[:a]).to eq('A2')
    end

    vache[:a] ||= 'A3'

    expect(vache[:a]).to eq('A2')
  end

  describe 'can enumerate over keys with #each' do
    it 'returns an enumerator when called with no block' do
      vache = Vache::Hash.new

      vache.store(:a, 'A', ttl: 10)
      vache.store(:b, 'B', ttl: 15)

      enumerator = vache.each

      expect(enumerator).to be_kind_of(Enumerator)
      expect(enumerator.to_a).to eq([ [ :a, 'A' ], [ :b, 'B' ] ])

      Timecop.freeze(Time.now + 11) do
        enumerator = vache.each

        expect(enumerator.to_a).to eq([ [ :b, 'B' ] ])
      end
    end

    it 'returns itself when called with no block' do
      vache = Vache::Hash.new

      vache.store(:a, 'A', ttl: 10)
      vache.store(:b, 'B', ttl: 15)

      array = [ ]
      result = vache.each do |pair|
        array << pair
      end

      expect(result).to be(vache)
      expect(array).to eq([ [ :a, 'A' ], [ :b, 'B' ] ])

      Timecop.freeze(Time.now + 11) do
        array = [ ]
        result = vache.each do |pair|
          array << pair
        end
      
        expect(array).to eq([ [ :b, 'B' ] ])
      end
    end
  end
end
