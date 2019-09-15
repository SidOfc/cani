lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cani/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 2.1'
  spec.name                  = 'cani'
  spec.version               = Cani::VERSION
  spec.authors               = ['Sidney Liebrand']
  spec.email                 = ['sidneyliebrand@gmail.com']

  spec.summary               = 'A simple caniuse CLI.'
  spec.description           = 'An interactive TUI (using FZF / Curses) ' \
                               'for exploring caniuse.com in your terminal.'
  spec.homepage              = 'https://github.com/SidOfc/cani'
  spec.license               = 'MIT'

  spec.files                 = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features|assets)/})
    end
  end

  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.executables << 'cani'

  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'curses'
  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'tty-screen'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'rspec'
end
