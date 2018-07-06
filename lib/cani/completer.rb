module Cani
  module Completer
    NAMES = {
      'ie'      => 'Internet Explorer',
      'edge'    => 'Edge',
      'ff'      => 'Firefox',
      'chr'     => 'Chrome',
      'saf'     => 'Safari',
      'op'      => 'Opera',
      'saf.ios' => 'IOS Safari',
      'o.mini'  => 'Opera Mini',
      'and'     => 'Android Browser',
      'bb'      => 'BlackBerry Browser',
      'o.mob'   => 'Opera Mobile',
      'chr.and' => 'Chrome for Android',
      'ff.and'  => 'Firefox for Android',
      'ie.mob'  => 'Internet Explorer Mobile',
      'uc'      => 'UC Browser for android',
      'ss'      => 'Samsung Internet',
      'qq'      => 'QQ Browser',
      'baidu'   => 'Baidu Browser'
    }.freeze

    def self.generate_fish
      gem_root = File.join File.dirname(__FILE__), '../../'
      tpl      = File.read File.join(gem_root, 'shell/completions/functions.fish')
      shw      = NAMES.reduce(String.new) do |acc, (k, v)|
        [acc, "complete -f -c cani -n '__fish_cani_using_command show' -a '#{k}' -d '#{v}'",
         "complete -f -c cani -n '__fish_cani_showing_browser #{k}' -a '#{Cani.find_browser(k).versions.reverse.join(' ')}'"].join("\n")
      end

      File.open(File.join(gem_root, 'shell/tmp.fish'), 'w') { |f| f << tpl + shw }
    end

    def self.generate_zsh
      gem_root  = File.join File.dirname(__FILE__), '../../'
      tpl       = File.read File.join(gem_root, 'shell/completions/functions.zsh')
      indent    = 10

      versions  = NAMES.keys.map do |name|
        next unless browser = Cani.find_browser(name)

        [(' ' * (indent - 2)) + name + ')',
         (' ' * indent) + "_arguments -C \"1: :(#{browser.versions.join(' ')})\"",
         (' ' * indent) + ';;'].join("\n")
      end.compact.join("\n").lstrip

      processed = tpl.gsub('{{names}}', NAMES.keys.join(' '))
                     .gsub('{{versions}}', versions)

      File.open(File.join(gem_root, 'shell/tmp.zsh'), 'w') { |f| f << processed }
    end
  end
end
