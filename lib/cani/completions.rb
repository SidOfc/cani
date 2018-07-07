module Cani
  module Completions
    def self.generate_fish
      gem_root = File.join File.dirname(__FILE__), '../../'
      tpl      = File.read File.join(gem_root, 'shell/completions/functions.fish')
      shw      = Cani.api.browsers.reduce(String.new) do |acc, browser|
        [acc, "complete -f -c cani -n '__fish_cani_using_command show' -a '#{browser.abbr}' -d '#{browser.label}'",
         "complete -f -c cani -n '__fish_cani_showing_browser #{browser.abbr}' -a '#{browser.versions.reverse.join(' ')}'"].join("\n")
      end

      tpl + shw
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

      tpl.gsub('{{names}}', Cani.api.browsers.map(&:abbr).join(' '))
         .gsub('{{versions}}', versions)
    end

    def self.generate_bash
      gem_root  = File.join File.dirname(__FILE__), '../../'
      tpl       = File.read File.join(gem_root, 'shell/completions/functions.bash')
      indent    = 10
      versions  = Cani.api.browsers.reduce(String.new) do |acc, browser|
        acc + (' ' * (indent - 2)) + '"' + browser.abbr + "\")\n" +
        (' ' * indent) + "COMPREPLY=($(compgen -W \"#{browser.versions.join(' ')}\" ${COMP_WORDS[COMP_CWORD]}))\n" +
        (' ' * indent) + ";;\n"
      end.strip

      tpl.gsub('{{names}}', Cani.api.browsers.map(&:abbr).join(' '))
         .gsub('{{versions}}', versions)
    end

    def self.install!
      fish_dir = File.expand_path('~/.config/fish/completions')
      def_dir  = File.join File.dirname(Cani.config.default), 'completions'

      # create all parent folders
      FileUtils.mkdir_p fish_dir
      FileUtils.mkdir_p def_dir

      # write each completion file
      File.open(File.join(fish_dir, 'cani.fish'), 'w') do |file|
        file << generate_fish
      end

      %w[bash zsh].each do |shell|
        File.open(File.join(def_dir, "_cani.#{shell}"), 'w') do |file|
          file << send("generate_#{shell}")
        end
      end

      # append source lines to configurations
      insert_source_lines!
    end

    def self.remove!
      fish_dir  = File.expand_path '~/.config/fish/completions'
      def_dir   = File.join File.dirname(Cani.config.default), 'completions'
      fish_comp = File.join fish_dir, 'cani.fish'

      File.unlink fish_comp if File.exist? fish_comp

      %w[bash zsh].each do |shell|
        shell_comp = File.join def_dir, "_cani.#{shell}"

        File.unlink shell_comp if File.exist? shell_comp
      end

      # remove source lines to configurations
      delete_source_lines!
    end

    def self.delete_source_lines!
      comp_dir = File.join File.dirname(Cani.config.default), 'completions'
      %w[bash zsh].each do |shell|
        shellrc   = File.join(Dir.home, ".#{shell}rc")
        lines     = File.read(shellrc).split("\n")
        comp_path = File.join(comp_dir, "_cani.#{shell}")
        rm_idx    = lines.find_index { |l| l.match? comp_path }

        lines.delete_at rm_idx unless rm_idx.nil?
        File.write shellrc, lines.join("\n")
      end
    end

    def self.insert_source_lines!
      comp_dir = File.join File.dirname(Cani.config.default), 'completions'
      %w[bash zsh].each do |shell|
        shellrc   = File.join(Dir.home, ".#{shell}rc")
        lines     = File.read(shellrc).split("\n")
        comp_path = File.join(comp_dir, "_cani.#{shell}")
        src_line_idx = lines.find_index { |l| l.match? comp_path }

        if src_line_idx
          lines[src_line_idx] = "#{lines[src_line_idx][/^\s+/]}[ -f #{comp_path} ] && source #{comp_path}"
        else
          lines << "[ -f #{comp_path} ] && source #{comp_path}"
        end

        File.write(shellrc, lines.join("\n"))
      end
    end
  end
end
