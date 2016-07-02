# bash completion support for the gi wrapper for Git.
#
# Copyright (C) 2016 Kirill Gagarski <kirill.gagarski@gmail.com>
# This completion uses the routines defined in git-completion script 
# by Shawn O. Pearce <spearce@spearce.org>.
# Distributed under the GNU General Public License, version 2.0.
#
# The contained completion routines provide support for completing
# everything that git-completion can complete for gi wrapper and
# also provides support for abbreviated gi commands.
# To use these routines:
#
#    1) Place this file to the same directory as git-completion.
#       (git-completion can be named git-completion.bash or git)
#    2) Add the following line to your .bashrc/.zshrc:
#        source $GIT_COMPLETION_DIRECTORY/gi
#


if [[ ! -z ${BASH_SOURCE[0]} ]]; then
    __gi_my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

if [[ -f ${__gi_my_dir}/git-completion.bash ]]; then
    __gi_git_completion=${__gi_my_dir}/git-completion.bash
elif [[ -f ${__gi_my_dir}/git ]]; then
    __gi_git_completion=${__gi_my_dir}/git
fi

if [[ ! -z ${__gi_git_completion} ]]; then

. ${__gi_git_completion}

# Bash implementation uses COMP_POINT which cannot be processed by gi
# So we will use copy-pasted git-completion implementation
_gi_get_comp_words_by_ref ()
{
    local exclude cur_ words_ cword_
    if [ "$1" = "-n" ]; then
        exclude=$2
        shift 2
    fi
    __git_reassemble_comp_words_by_ref "$exclude"
    cur_=${words_[cword_]}
    while [ $# -gt 0 ]; do
        case "$1" in
        cur)
            cur=$cur_
            ;;
        prev)
            prev=${words_[$cword_-1]}
            ;;
        words)
            words=("${words_[@]}")
            ;;
        cword)
            cword=$cword_
            ;;
        esac
        shift
    done
}

__gi_restore_comp() {
    COMP_LINE=$1
    COMP_CWORD=$2
    COMP_WORDS=( "$3[@]" )
}

__gi_func_wrap ()
{
    local old_comp_line=${COMP_LINE}
    local old_comp_cword=${COMP_CWORD}
    local old_comp_words=( "${COMP_WORDS[@]}" )

    local is_empty_cword=False

    if [[ -z "${COMP_WORDS[${COMP_CWORD}]}" ]]; then
        is_empty_cword=True
    fi

    local helper_cli="${COMP_LINE} --gi-bash-completion-helper-with-comp-cword=${COMP_CWORD},${is_empty_cword}"
    local helper_output=()
    while IFS= read -r line; do
        helper_output+=( "$line" )
    done < <( ${helper_cli} )

    COMP_LINE="${helper_output[@]:2}"
    COMP_CWORD="${helper_output[1]}"
    COMP_WORDS=("${helper_output[@]:2}")

    if [[ ${helper_output[0]} == True ]]; then
        __gi_restore_comp old_comp_line old_comp_cword old_comp_words
        return 0
    fi

    _gi_get_comp_words_by_ref -n =: cur words cword prev
    $1
    __gi_restore_comp old_comp_line old_comp_cword old_comp_words
}

__gi_complete ()
{
    local wrapper="__gi_wrap${2}"
    eval "$wrapper () { __gi_func_wrap $2 ; }"
    complete -o bashdefault -o default -o nospace -F $wrapper $1 2>/dev/null \
        || complete -o default -o nospace -F $wrapper $1
}

__gi_complete gi __git_main

fi