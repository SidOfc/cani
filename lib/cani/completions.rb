module Cani
  module Completions
    def self.generate_fish
      gem_root = File.join File.dirname(__FILE__), '../../'
      tpl      = File.read File.join(gem_root, 'shell/completions/functions.fish')

      shw = Cani.api.browsers.reduce String.new do |acc, browser|
        versions = browser.versions.reverse.join(' ')
        acc +
          "\ncomplete -f -c cani -n '__fish_cani_using_command show' -a '#{browser.abbr}' -d '#{browser.label}'" +
          "\ncomplete -f -c cani -n '__fish_cani_showing_browser #{browser.abbr}' -a '#{versions}'"
      end

      use = Cani.api.features.reduce String.new do |acc, feature|
        description = feature.title.size > 40 ? feature.title[0..28] + '..' : feature.title
        acc +
          "\ncomplete -f -c cani -n '__fish_cani_using_command use' -a '#{feature.name}' -d '#{description}'"
      end

      tpl + shw + "\n" + use
    end

    def self.generate_zsh
      gem_root  = File.join File.dirname(__FILE__), '../../'
      tpl       = File.read File.join(gem_root, 'shell/completions/functions.zsh')
      indent    = 10
      versions  = Cani.api.browsers.reduce String.new do |acc, browser|
        acc + (' ' * (indent - 2)) + browser.abbr + ")\n" +
          (' ' * indent) + "_arguments -C \"1: :(#{browser.versions.join(' ')})\"\n" +
          (' ' * indent) + ";;\n"
      end.strip

      tpl.gsub('{{names}}', Cani.api.browsers.map(&:abbr).join(' '))
         .gsub('{{features}}', Cani.api.features.map(&:name).join(' '))
         .gsub '{{versions}}', versions
    end

    def self.generate_bash
      gem_root  = File.join File.dirname(__FILE__), '../../'
      tpl       = File.read File.join(gem_root, 'shell/completions/functions.bash')
      indent    = 10
      versions  = Cani.api.browsers.reduce String.new do |acc, browser|
        acc + (' ' * (indent - 2)) + '"' + browser.abbr + "\")\n" +
          (' ' * indent) + "COMPREPLY=($(compgen -W \"#{browser.versions.join(' ')}\" ${COMP_WORDS[COMP_CWORD]}))\n" +
          (' ' * indent) + ";;\n"
      end.strip

      tpl.gsub('{{names}}', Cani.api.browsers.map(&:abbr).join(' '))
         .gsub('{{features}}', Cani.api.features.map(&:name).join(' '))
         .gsub '{{versions}}', versions
    end

    def self.install!
      # create all parent folders
      FileUtils.mkdir_p Cani.config.fish_comp_dir
      FileUtils.mkdir_p Cani.config.comp_dir

      %w[bash zsh fish].each do |shell|
        File.open completion_path(shell), 'w' do |file|
          file << send("generate_#{shell}")
        end
      end

      # append source lines to configurations
      insert_source_lines!
    end

    def self.remove!
      %w[bash zsh fish].each do |shell|
        shell_comp = completion_path shell

        File.unlink shell_comp if File.exist? shell_comp
      end

      # remove source lines to configurations
      delete_source_lines!
    end

    def self.paths
      puts "fish: #{completion_path(:fish)}"
      puts "bash: #{completion_path(:bash)}"
      puts "zsh:  #{completion_path(:zsh)}"
    end

    def self.completion_path(shell)
      return File.join Cani.config.fish_comp_dir, 'cani.fish' if shell == :fish

      File.join Cani.config.comp_dir, "_cani.#{shell}"
    end

    def self.compile_source_line(path)
      return "test -e #{path}; and source #{path}" if path.end_with? '.fish'

      "[ -f #{path} ] && source #{path}"
    end

    def self.delete_source_lines!
      return unless Cani.config.modify_shell_configs

      %w[bash zsh].each do |shell|
        shellrc = File.join Dir.home, ".#{shell}rc"

        next unless File.exist? shellrc

        lines     = File.read(shellrc).split "\n"
        comp_path = completion_path shell
        comp_src  = compile_source_line comp_path
        rm_idx    = lines.find_index { |l| l.match comp_src }

        lines.delete_at rm_idx unless rm_idx.nil?
        File.write shellrc, lines.join("\n")
      end
    end

    def self.insert_source_lines!
      return unless Cani.config.modify_shell_configs

      %w[bash zsh].each do |shell|
        shellrc = File.join Dir.home, ".#{shell}rc"

        next unless File.exist? shellrc

        lines     = File.read(shellrc).split "\n"
        comp_path = completion_path shell
        comp_src  = compile_source_line comp_path

        lines << comp_src \
          unless lines.find_index { |l| l.match comp_src }

        File.write shellrc, lines.join("\n")
      end
    end
  end
end
