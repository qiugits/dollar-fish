# name: dollar
# ---------------
# Based on clearance and bobthefish. Display the following bits on the left:
# - Virtualenv name (if applicable, see https://github.com/adambrenecki/virtualfish)
# - Git branch and dirty state (if inside a git repo)


# ============
# Fish Prompt
# ============
function fish_prompt -d 'dollar, a fish theme optimized for awesome'
  set -l last_status $status

  set -l cyan (set_color cyan)
  set -l yellow (set_color yellow)
  set -l red (set_color red)
  set -l blue (set_color blue)
  set -l green (set_color green)
  set -l normal (set_color normal)

  set -l cwd $blue(pwd | sed "s:^$HOME:~:")

  # Output the prompt, left to right

  # Add a newline before new prompts
  #echo -e ''

  # Display [venvname] if in a virtualenv
  if set -q VIRTUAL_ENV
      echo -n -s (set_color -b cyan black) '[' (basename "$VIRTUAL_ENV") ']' $normal ' '
  end

  # Print pwd or full path
  #echo -n -s $cwd $normal

  set -l prompt_color $red
  if test $last_status = 0
    set prompt_color $yellow
  end

  # Terminate with a nice prompt char
  echo -e -n -s $prompt_color '$ ' $normal
end
