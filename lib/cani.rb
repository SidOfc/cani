# frozen_string_literal: true

require 'colorize'
require 'json'
require 'yaml'

require 'cani/version'
require 'cani/config'
require 'cani/api'
require 'cani/feature'
require 'cani/browser'

# Cani
module Cani
  class SubjectNotFound < StandardError; end
  class SettingNotFound < StandardError; end
  class FeatureNotFound < StandardError; end
  class BrowserNotFound < StandardError; end
  class CommandNotFound < StandardError; end

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
    puts '   show BROWSER            show information about specific browser'
    puts '   list TYPE               list names of each item in TYPE'
    puts '                           TYPE can be "features" or "browsers"'
    puts ''
    puts 'Options:'
    puts '   -h   --help             show this help'
    puts '   -v   --version          print the version number'
    puts ''
    puts 'Examples:'
    puts '   cani -h'
    puts '   cani --version'
    puts '   cani use box-shadow'
    puts '   cani show ie'
    puts '   cani list features'

    exit
  end

  def self.print_browsers
    api.browsers.each { |browser| $stdout.puts browser }
    $stdout.flush
  end

  def self.print_features
    api.features.each { |feature| $stdout.puts api.data['data'][feature]['title'] }
    $stdout.flush
  end

  def self.use
  end

  def self.fzf_rows(rows)
    col_widths = []

    rows.each do |row|
      row.each.with_index do |column, i|
        col_width     = column.size
        col_widths[i] = col_width if col_width > col_widths[i].to_i
      end
    end

    rows.map do |row|
      row.map.with_index { |col, i| col.to_s.ljust(col_widths[i]) }
         .join('   ').rstrip
    end
  end

  def self.headerify(input)
    input.to_s.strip.downcase
  end

  def self.fzf(rows, **opts)
    header = '[' + [:cani, *opts.fetch(:header, [])].map(&method(:headerify)).join(':') + ']'
    `echo "#{fzf_rows(rows).join("\n")}" | fzf --header="#{header}"`.split('   ')
  end

  def self.show(brws = config.args[1], version = config.args[2])
    browser = find_browser brws

    if browser
      if version
        rows = browser.rows_for version: version, columns: %i[status support title],
                                types: %i[supported partial prefix unsupported]

        fzf(rows, header: [:show, browser.title, version, :features])
        show browser.title, nil
      else
        rows = browser.usage.map { |(v, u)| [v, 'usage: ' + format('%.4f%%', u)] }.reverse

        if (version = fzf(rows, header: [:show, browser.title, :versions]).first)
          show browser.title, version
        else
          show nil, nil
        end
      end
    else
      rows    = api.browsers.map { |bwsr| [bwsr.title, 'usage: ' + format('%.4f%%', bwsr.usage.values.sum)] }
      browser = find_browser fzf(rows, header: [:show, :browsers]).first

      show browser.title, nil unless browser.nil?
    end
  end

  def self.find_browser(name)
    name = name.to_s.downcase
    idx  = api.browsers.find_index { |bwsr| bwsr.title.downcase == name }

    api.browsers[idx] if idx
  end

  def self.run(cmd = nil)
    cmd ||= config.args.first

    if cmd && respond_to?(cmd)
      send cmd
    else
      cmd = fzf([['show', 'Show browser info'], ['use', 'Show feature info']], header: ['commands']).first

      if cmd
        run cmd
      end
    end
  end
end
