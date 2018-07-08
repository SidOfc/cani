module Cani
  class Api
    class Config
      attr_reader :settings

      FILE          = File.join(Dir.home, '.config', 'cani', 'config.yml').freeze
      DIRECTORY     = File.dirname(FILE).freeze
      COMP_DIR      = File.join(DIRECTORY, 'completions').freeze
      FISH_DIR      = File.join(Dir.home, '.config', 'fish').freeze
      FISH_COMP_DIR = File.join(FISH_DIR, 'completions').freeze
      DEFAULTS      = {
        # data settings
        'expire'   => 86_400,
        'source'   => 'https://raw.githubusercontent.com/Fyrd/caniuse/master/data.json',

        # usage settings
        'versions' => 1,
        'browsers' => %w[chrome firefox edge ie safari ios_saf opera android bb]
      }.freeze

      def initialize(**opts)
        @settings = DEFAULTS.merge opts

        if File.exist? file
          @settings.merge! YAML.load_file(file)
        else
          create!
        end
      end

      def file
        FILE
      end

      def directory
        DIRECTORY
      end

      def comp_dir
        COMP_DIR
      end

      def fish_dir
        FISH_DIR
      end

      def fish_comp_dir
        FISH_COMP_DIR
      end

      def flags
        @flags ||= ARGV.select { |arg| arg.start_with? '-' }
      end

      def args
        @args ||= ARGV.reject { |arg| arg.start_with? '-' }
      end

      def remove!
        File.unlink file if File.exist? file
      end

      def install!
        FileUtils.mkdir_p directory
        File.open file, 'w' do |f|
          f << "# this is the default configuration file for the \"Cani\" RubyGem.\n"
          f << "# it contains some options to control what is shown, when new data\n"
          f << "# is fetched, where it should be fetched from.\n"
          f << "# documentation: https://github.com/sidofc/cani\n"
          f << "# rubygems: https://rubygems.org/gems/cani\n\n"
          f << "# the \"expire\" key defines the interval at which new data is\n"
          f << "# fetched from \"source\". It's value is passed in as seconds.\n"
          f << "# 86400 seconds => 24 hours so by default, new data will be fetched every day\n"
          f << "expire: #{expire}\n\n"
          f << "# the \"source\" key is used to fetch the data required for\n"
          f << "# this command to work.\n"
          f << "source: #{source}\n\n"
          f << "# the \"versions\" key defines how many versions of support\n"
          f << "# will be shown in the \"use\" command\n"
          f << "versions: #{versions}\n\n"
          f << "# the \"browsers\" key defines which browsers are shown\n"
          f << "# in the \"use\" command\n"
          f << "browsers:\n"
          f << "  # shown:\n"
          f << browsers.map { |bn| "  - #{bn}" }.join("\n") + "\n"
          f << "  # hidden:\n"
          f << (Cani.api.browsers.map(&:name) - browsers).map { |bn| "  # - #{bn}" }.join("\n")
        end
      end

      def method_missing(mtd, *args, &block)
        settings.key?(mtd.to_s) ? settings[mtd.to_s] : super
      end

      def respond_to_missing?(mtd, include_private = false)
        settings.key? mtd.to_s
      end
    end
  end
end
