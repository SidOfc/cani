module Cani
  class Config
    attr_reader :settings

    DEFAULTS = {
      expire: 86_400,
      versions: 1,
      source: 'https://raw.githubusercontent.com/Fyrd/caniuse/master/data.json',
      show: %w[chrome firefox edge ie safari ios_saf opera android bb],
      default: File.expand_path('~/.config/cani/config.yml'),
      aliases: { 'firefox' => 'ff', 'chrome' => 'chr', 'safari' => 'saf',
                 'ios_saf' => 'saf_ios', 'opera' => 'opr',
                 'op_mob' => 'opr_mob', 'android' => 'andr' },
      statuses: { 'rec' => 'rc', 'unoff' => 'un', 'other' => 'ot' },
      stat_symbols: { 'n' => '-', 'y' => '+', 'p' => '~', 'u' => '*' }
    }.freeze

    def initialize(**opts)
      @settings = DEFAULTS.dup.merge opts

      if File.exist? default
        @settings.merge! YAML.load_file(default)
      else
        create_default
      end
    end

    def flags
      @flags ||= ARGV.select { |arg| arg.start_with? '-' }
    end

    def args
      @args ||= ARGV.reject { |arg| arg.start_with? '-' }
    end

    def create_default
      root = File.expand_path '~/.config/cani'
      FileUtils.mkdir_p root
      File.open(default, 'w') { |f| f << YAML.dump(settings) }
    end

    def method_missing(mtd, *args, &block)
      settings.key?(mtd) ? settings[mtd] : super
    end

    def respond_to_missing?(mtd, include_private = false)
      settings.key? mtd
    end
  end
end
