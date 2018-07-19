# This is a template file that adds the most basic top level completions.
# It is used during installation of completions via the CLI.
# Unlike the functions.fish file, this one cannot be run directly.
#
# The invalid syntax will be replaced with valid BASH code
# during the installation process.

_cani_completions() {
  case "${COMP_WORDS[1]}" in
    "show")
      case "${COMP_WORDS[2]}" in
        {{versions}}
        *)
            COMPREPLY=($(compgen -W "{{names}}" "${COMP_WORDS[COMP_CWORD]}"))
          ;;
      esac
      ;;
    "use")
      COMPREPLY=($(compgen -W "{{features}}" "${COMP_WORDS[COMP_CWORD]}"))
      ;;
    *)
      COMPREPLY=($(compgen -W "use show help version update purge install_completions" "${COMP_WORDS[COMP_CWORD]}"))
      ;;
  esac
}

complete -F _cani_completions cani


