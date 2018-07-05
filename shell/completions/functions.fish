# This is a template file that adds the most basic top level completions.
# It is used during installation of completions via the CLI.
#
# Extra completions are added in the installation process.
# These include completions for browsers and versions.

function __fish_cani_needs_command
  set -l cmd (commandline -opc)
  set -q cmd[2]
  or return 0

  echo $cmd[2..-1]
  return 1
end

function __fish_cani_showing_browser
  set -l cmd (__fish_cani_needs_command | string split ' ')

  test "$cmd[1]" = "show"
  and contains -- "$cmd[2]" $argv
  and return 0
end

function __fish_cani_using_command
  set -l cmd (__fish_cani_needs_command)

  test -z "$cmd"
  and return 1

  contains -- $cmd $argv
  and return 0
end

complete -f -c cani

complete -f -c cani -n '__fish_cani_needs_command' -a 'use' -d 'Display an overview of features including support'
complete -f -c cani -n '__fish_cani_needs_command' -a 'show' -d 'Display feature support for a specific browser'
complete -f -c cani -n '__fish_cani_needs_command' -a 'help' -d 'Show command help'
complete -f -c cani -n '__fish_cani_needs_command' -a 'version' -d 'Print the version number'
