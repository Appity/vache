require_relative 'lib/vache/version'

Gem::Specification.new do |spec|
  spec.name = 'vache'
  spec.version = Vache::VERSION
  spec.authors = [ 'Scott Tadman' ]
  spec.email = %w[ tadman@appity.studio ]

  spec.summary = %q{Variable Expiry Time Hash}
  spec.description = %q{A Hash-like structure with flexible data expiration options which can serve as many things, including a cache.}
  spec.homepage = 'https://github.com/appity/vache'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.1.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/appity/vache'
  spec.metadata['changelog_uri'] = 'https://github.com/appity/vache'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w[ lib ]
end
