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
  end
end
