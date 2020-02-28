RSpec.describe Vache do
  it 'has a version number' do
    expect(Vache.version).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
