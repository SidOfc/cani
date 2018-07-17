lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cani/version'

Gem::Specification.new do |spec|
  spec.name          = 'cani'
  spec.version       = Cani::VERSION
  spec.authors       = ['Sidney Liebrand']
  spec.email         = ['sidneyliebrand@gmail.com']

  spec.summary       = 'A simple caniuse CLI.'
  spec.description   = 'A rework of the ruby script from my medium post: https://medium.com/@sidneyliebrand/combining-caniuse-with-fzf-fb93ad235bae'
  spec.homepage      = 'https://github.com/SidOfc/cani'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features|assets)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'curses'
  spec.add_runtime_dependency 'json'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
