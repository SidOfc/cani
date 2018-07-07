# frozen_string_literal: true

require 'colorize'
require 'json'
require 'yaml'

require 'cani/version'
require 'cani/config'
require 'cani/api'
require 'cani/completions'

# Cani
module Cani
  def self.config(**opts)
    @settings ||= Config.new(**opts)
  end

  def self.api
    @api ||= Api.new
  end

  def self.help
    puts "Cani #{VERSION} <https://github.com/SidOfc/cani>"
    puts ''
    puts 'Usage: cani [COMMAND [ARGUMENTS]] [OPTIONS]'
    puts ''
    puts 'Commands:'
    puts '   use FEATURE             show browser support for FEATURE'
    puts '   show BROWSER            show information about specific BROWSER'
    puts '   help                    show this help'
    puts '   version                 print the version number'
    puts ''
    puts 'Examples:'
    puts '   cani use'
    puts '   cani show ie'
    puts '   cani show chr.and'
  end

  def self.version
    puts Cani::VERSION
  end

  def self.edit
    system ENV.fetch('EDITOR', 'vim'), api.config.default
  end

  def self.use
    puts Fzf.pick Fzf.feature_rows,
                  header: 'use]   [' + Api::Feature.support_legend,
                  colors: %i[green light_black light_white light_black]
  end

  def self.show(brws = api.config.args[1], version = api.config.args[2])
    browser = api.find_browser brws

    if browser
      if version
        Fzf.pick Fzf.browser_feature_rows(browser, version),
                 header: "show:#{browser.title.downcase}:#{version}]   [#{Api::Feature.support_legend}",
                 colors: [:green, :light_black, :light_white]

        show browser.title, nil
      else
        if (version = Fzf.pick(Fzf.browser_usage_rows(browser),
                               header: [:show, browser.title],
                               colors: %i[white light_black]).first)
          show browser.title, version
        else
          show nil, nil
        end
      end
    else
      browser = api.find_browser Fzf.pick(Fzf.browser_rows,
                                          header: [:show],
                                          colors: %i[white light_black]).first

      show browser.title, nil unless browser.nil?
    end
  end
end
