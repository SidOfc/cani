module Cani
  module Completer
    def self.generate_fish
      gem_root = File.join File.dirname(__FILE__), '../../'
      tpl      = File.read File.join(gem_root, 'shell/completions/functions.fish')
      shw      = Cani.api.browsers.reduce(String.new) do |acc, browser|
        [acc, "complete -f -c cani -n '__fish_cani_using_command show' -a '#{browser.abbr}' -d '#{browser.label}'",
         "complete -f -c cani -n '__fish_cani_showing_browser #{browser.abbr}' -a '#{browser.versions.reverse.join(' ')}'"].join("\n")
      end

      File.open(File.join(gem_root, 'shell/tmp.fish'), 'w') { |f| f << tpl + shw }
    end

    def self.generate_zsh
      gem_root  = File.join File.dirname(__FILE__), '../../'
      tpl       = File.read File.join(gem_root, 'shell/completions/functions.zsh')
      indent    = 10
      versions  = Cani.api.browsers.reduce(String.new) do |acc, browser|
        acc + (' ' * (indent - 2)) + browser.abbr + ")\n" +
        (' ' * indent) + "_arguments -C \"1: :(#{browser.versions.join(' ')})\"\n" +
        (' ' * indent) + ";;\n"
      end.strip

      processed = tpl.gsub('{{names}}', Cani.api.browsers.map(&:abbr).join(' '))
                     .gsub('{{versions}}', versions)

      File.open(File.join(gem_root, 'shell/tmp.zsh'), 'w') { |f| f << processed }
    end
  end
end
