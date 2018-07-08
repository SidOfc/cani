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
        'expire'   => 86_400,
        'versions' => 1,
        'source'   => 'https://raw.githubusercontent.com/Fyrd/caniuse/master/data.json',
        'show'     => %w[chrome firefox edge ie safari ios_saf opera android bb]
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
          f << "# rubygems: https://rubygems.org/gems/cani\n"
          f << YAML.dump(settings) + "\n"
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
