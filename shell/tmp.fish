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

complete -f -c cani -n '__fish_cani_using_command show' -a 'ie' -d 'Internet Explorer'
complete -f -c cani -n '__fish_cani_showing_browser ie' -a '11 10 9 8 7 6 5.5'
complete -f -c cani -n '__fish_cani_using_command show' -a 'edge' -d 'Edge'
complete -f -c cani -n '__fish_cani_showing_browser edge' -a '18 17 16 15 14 13 12'
complete -f -c cani -n '__fish_cani_using_command show' -a 'ff' -d 'Firefox'
complete -f -c cani -n '__fish_cani_showing_browser ff' -a '62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3.6 3.5 3 2'
complete -f -c cani -n '__fish_cani_using_command show' -a 'chr' -d 'Chrome'
complete -f -c cani -n '__fish_cani_showing_browser chr' -a '70 69 68 67 66 65 64 63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4'
complete -f -c cani -n '__fish_cani_using_command show' -a 'saf' -d 'Safari'
complete -f -c cani -n '__fish_cani_showing_browser saf' -a 'TP 12 11.1 11 10.1 10 9.1 9 8 7.1 7 6.1 6 5.1 5 4 3.2 3.1'
complete -f -c cani -n '__fish_cani_using_command show' -a 'op' -d 'Opera'
complete -f -c cani -n '__fish_cani_showing_browser op' -a '53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 12.1 12 11.6 11.5 11.1 11 10.6 10.5 10.0-10.1 9.5-9.6 9'
complete -f -c cani -n '__fish_cani_using_command show' -a 'saf.ios' -d 'IOS Safari'
complete -f -c cani -n '__fish_cani_showing_browser saf.ios' -a '11.3 11.0-11.2 10.3 10.0-10.2 9.3 9.0-9.2 8.1-8.4 8 7.0-7.1 6.0-6.1 5.0-5.1 4.2-4.3 4.0-4.1 3.2'
complete -f -c cani -n '__fish_cani_using_command show' -a 'o.mini' -d 'Opera Mini'
complete -f -c cani -n '__fish_cani_showing_browser o.mini' -a 'all'
complete -f -c cani -n '__fish_cani_using_command show' -a 'and' -d 'Android Browser'
complete -f -c cani -n '__fish_cani_showing_browser and' -a '67 4.4.3-4.4.4 4.4 4.2-4.3 4.1 4 3 2.3 2.2 2.1'
complete -f -c cani -n '__fish_cani_using_command show' -a 'bb' -d 'BlackBerry Browser'
complete -f -c cani -n '__fish_cani_showing_browser bb' -a '10 7'
complete -f -c cani -n '__fish_cani_using_command show' -a 'o.mob' -d 'Opera Mobile'
complete -f -c cani -n '__fish_cani_showing_browser o.mob' -a '46 12.1 12 11.5 11.1 11 10'
complete -f -c cani -n '__fish_cani_using_command show' -a 'chr.and' -d 'Chrome for Android'
complete -f -c cani -n '__fish_cani_showing_browser chr.and' -a '67'
complete -f -c cani -n '__fish_cani_using_command show' -a 'ff.and' -d 'Firefox for Android'
complete -f -c cani -n '__fish_cani_showing_browser ff.and' -a '60'
complete -f -c cani -n '__fish_cani_using_command show' -a 'ie.mob' -d 'Internet Explorer Mobile'
complete -f -c cani -n '__fish_cani_showing_browser ie.mob' -a '11 10'
complete -f -c cani -n '__fish_cani_using_command show' -a 'uc' -d 'UC Browser for android'
complete -f -c cani -n '__fish_cani_showing_browser uc' -a '11.8'
complete -f -c cani -n '__fish_cani_using_command show' -a 'ss' -d 'Samsung Internet'
complete -f -c cani -n '__fish_cani_showing_browser ss' -a '7.2 6.2 5 4'
complete -f -c cani -n '__fish_cani_using_command show' -a 'qq' -d 'QQ Browser'
complete -f -c cani -n '__fish_cani_showing_browser qq' -a '1.2'
complete -f -c cani -n '__fish_cani_using_command show' -a 'baidu' -d 'Baidu Browser'
complete -f -c cani -n '__fish_cani_showing_browser baidu' -a '7.12'