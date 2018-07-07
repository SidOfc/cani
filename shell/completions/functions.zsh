# This is a template file that adds the most basic top level completions.
# It is used during installation of completions via the CLI.
# Unlike the functions.fish file, this one cannot be run directly.
#
# The invalid syntax will be replaced with valid ZSH code
# during the installation process.

function _cani {
  local line

  _arguments -C "1: :(use show help version)" \
                "*::arg:->args"

  case $line[1] in
    show)
      _arguments -C "1: :({{names}})" \
                    "*::arg:->args"

      case $line[1] in
        {{versions}}
      esac
      ;;
  esac
}

compdef _cani cani
