module Cani
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
      'browsers' => %w[ie edge chrome firefox safari ios_saf opera android bb],
      'navigate' => 'always'
    }.freeze

    def initialize(**opts)
      @settings = DEFAULTS.merge opts

      if File.exist? file
        if (yml = YAML.load_file(file))
          @settings.merge! yml
        end
      else
        install!
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

    def remove!
      File.unlink file if File.exist? file
      FileUtils.rm_rf directory if Dir.exist? directory
    end

    def nav_type?(type)
      navigate == type.to_s
    end

    def install!
      hrs  = (DEFAULTS['expire'] / 3600.to_f).round 2
      days = (hrs / 24.to_f).round 2
      wk   = (days / 7.to_f).round 2
      mo   = (days / 30.to_f).round 2
      tstr = if mo >= 1
               "#{mo == mo.to_i ? mo.to_i : mo} month#{mo != 1 ? 's' : ''}"
             elsif wk >= 1
               "#{wk == wk.to_i ? wk.to_i : wk} week#{wk != 1 ? 's' : ''}"
             elsif days >= 1
               "#{days == days.to_i ? days.to_i : days} day#{days != 1 ? 's' : ''}"
             else
               "#{hrs == hrs.to_i ? hrs.to_i : hrs} hour#{hrs != 1 ? 's' : ''}"
             end

      FileUtils.mkdir_p directory
      File.open file, 'w' do |f|
        f << "---\n"
        f << "# this is the default configuration file for the \"Cani\" RubyGem.\n"
        f << "# it contains some options to control what is shown, when new data\n"
        f << "# is fetched, where it should be fetched from.\n"
        f << "# documentation: https://github.com/sidofc/cani\n"
        f << "# rubygems: https://rubygems.org/gems/cani\n\n"
        f << "# the \"expire\" key defines the interval at which new data is\n"
        f << "# fetched from \"source\". It's value is passed in as seconds\n"
        f << "# default value: #{DEFAULTS['expire']} # => #{tstr}\n"
        f << "expire: #{expire}\n\n"
        f << "# the \"source\" key is used to fetch the data required for\n"
        f << "# this command to work.\n"
        f << "source: #{source}\n\n"
        f << "# navigating means reopening the previously open window when going back by pressing <escape>\n"
        f << "# or opening the next menu by selecting an entry in fzf with <enter>\n"
        f << "# there are two different navigation modes:\n"
        f << "#   * 'always'  - always navigate back to the previous menu, exit only at root menu with <escape>\n"
        f << "#   * 'forward' - only allow navigating forward and backwards upto the menu that cani was initially open\n"
        f << "navigate: #{navigate}\n\n"
        f << "# the \"versions\" key defines how many versions of support\n"
        f << "# will be shown in the \"use\" command\n"
        f << "# e.g. `-ie +edge` becomes `--ie ++edge` when this is set to 2, etc...\n"
        f << "versions: #{versions}\n\n"
        f << "# the \"browsers\" key defines which browsers are shown\n"
        f << "# in the \"use\" command\n"
        f << "browsers:\n"
        f << browsers.map { |bn| "  - #{bn}" }.join("\n") + "\n"
        f << (Cani.api.browsers.map(&:name) - browsers).map { |bn| "  # - #{bn}" }.join("\n")
      end

      Completions.install!
    end

    def method_missing(mtd, *args, &block)
      settings.key?(mtd.to_s) ? settings[mtd.to_s] : super
    end

    def respond_to_missing?(mtd, include_private = false)
      settings.key? mtd.to_s
    end
  end
end
