# You can override some default right prompt options in your config.fish:
#     set -g theme_date_format "+%a %H:%M"

# name: dollar
#
# dollar is a Powerline-style, Git-aware fish theme optimized for awesome.
#
# You will need a Powerline-patched font for this to work:
#
#     https://powerline.readthedocs.org/en/master/installation.html#patched-fonts
#
# I recommend picking one of these:
#
#     https://github.com/Lokaltog/powerline-fonts
#
# For more advanced awesome, install a nerd fonts patched font (and be sure to
# enable nerd fonts support with `set -g theme_nerd_fonts yes`):
#
#     https://github.com/ryanoasis/nerd-fonts
#
# You can override some default prompt options in your config.fish:
#
#     set -g theme_display_git no
#     set -g theme_display_git_dirty no
#     set -g theme_display_git_untracked no
#     set -g theme_display_git_ahead_verbose yes
#     set -g theme_git_worktree_support yes
#     set -g theme_display_vagrant yes
#     set -g theme_display_docker_machine no
#     set -g theme_display_k8s_context no
#     set -g theme_display_hg yes
#     set -g theme_display_virtualenv no
#     set -g theme_display_ruby no
#     set -g theme_display_user yes
#     set -g theme_display_hostname yes
#     set -g theme_display_vi no
#     set -g theme_avoid_ambiguous_glyphs yes
#     set -g theme_powerline_fonts no
#     set -g theme_nerd_fonts yes
#     set -g theme_show_exit_status yes
#     set -g default_user your_normal_user
#     set -g theme_color_scheme dark
#     set -g fish_prompt_pwd_dir_length 0
#     set -g theme_project_dir_length 1
#     set -g theme_newline_cursor yes


# ==============================
# Helper methods
# ==============================

function __dollar_basename -d 'basically basename, but faster'
  string replace -r '^.*/' '' -- $argv
end

function __dollar_dirname -d 'basically dirname, but faster'
  string replace -r '/[^/]+/?$' '' -- $argv
end

function __dollar_git_branch -S -d 'Get the current git branch (or commitish)'
  set -l ref (command git symbolic-ref HEAD ^/dev/null)  # ex: $ref => 'refs/heads/master'
    and string replace 'refs/heads/' " $__dollar_branch_glyph " $ref  # whether to insert space here: ~/w/p/dollar-fish**master
    and return

  set -l tag (command git describe --tags --exact-match ^/dev/null)
    and echo "$__dollar_tag_glyph $tag"
    and return

  set -l branch (command git show-ref --head -s --abbrev | head -n1 ^/dev/null)
  echo "$__dollar_detached_glyph $branch"
end

function __dollar_hg_branch -S -d 'Get the current hg branch'
  set -l branch (command hg branch ^/dev/null)
  set -l book (command hg book | command grep \* | cut -d\  -f3)
  echo "$__dollar_branch_glyph$branch @ $book"
end

function __dollar_pretty_parent -S -a current_dir -d 'Print a parent directory, shortened to fit the prompt'
  set -q fish_prompt_pwd_dir_length
    or set -l fish_prompt_pwd_dir_length 1

  # Replace $HOME with ~
  set -l real_home ~
  set -l parent_dir (string replace -r '^'"$real_home"'($|/)' '~$1' (__dollar_dirname $current_dir))

  # Must check whether `$parent_dir = /` if using native dirname
  if [ -z "$parent_dir" ]
    echo -ns /  # unnessary -s ?
    return
  end

  if [ $fish_prompt_pwd_dir_length -eq 0 ]
    echo -ns "$parent_dir/"  # unnessary -s ?
    return
  end

  string replace -ar '(\.?[^/]{'"$fish_prompt_pwd_dir_length"'})[^/]*/' '$1/' "$parent_dir/"
end

function __dollar_ignore_vcs_dir -d 'Check whether the current directory should be ignored as a VCS segment'
  for p in $theme_vcs_ignore_paths
    set ignore_path (realpath $p ^/dev/null)
    switch $PWD/
      case $ignore_path/\*
        echo 1
        return
    end
  end
end

function __dollar_git_project_dir -S -d 'Print the current git project base directory'
  [ "$theme_display_git" = 'no' ]; and return

  set -q theme_vcs_ignore_paths
    and [ (__dollar_ignore_vcs_dir) ]
    and return

  if [ "$theme_git_worktree_support" != 'yes' ]
    command git rev-parse --show-toplevel ^/dev/null
    return
  end

  set -l git_dir (command git rev-parse --git-dir ^/dev/null); or return

  pushd $git_dir
  set git_dir $PWD
  popd

  switch $PWD/
    case $git_dir/\*
      # Nothing works quite right if we're inside the git dir
      # TODO: fix the underlying issues then re-enable the stuff below

      # # if we're inside the git dir, sweet. just return that.
      # set -l toplevel (command git rev-parse --show-toplevel ^/dev/null)
      # if [ "$toplevel" ]
      #   switch $git_dir/
      #     case $toplevel/\*
      #       echo $git_dir
      #   end
      # end
      return
  end

  set -l project_dir (__dollar_dirname $git_dir)

  switch $PWD/
    case $project_dir/\*
      echo $project_dir
      return
  end

  set project_dir (command git rev-parse --show-toplevel ^/dev/null)
  switch $PWD/
    case $project_dir/\*
      echo $project_dir
  end
end

function __dollar_hg_project_dir -S -d 'Print the current hg project base directory'
  [ "$theme_display_hg" = 'yes' ]; or return

  set -q theme_vcs_ignore_paths
    and [ (__dollar_ignore_vcs_dir) ]
    and return

  set -l d $PWD
  # Must check whether `$d = /` if using native dirname
  while not [ -z "$d" ]
    if [ -e $d/.hg ]
      command hg root --cwd "$d" ^/dev/null
      return
    end
    set d (__dollar_dirname $d)
  end
end

function __dollar_project_pwd -S -a current_dir -d 'Print the working directory relative to project root'
  set -q theme_project_dir_length
    or set -l theme_project_dir_length 0

  set -l project_dir (string replace -r '^'"$current_dir"'($|/)' '' $PWD)

  if [ $theme_project_dir_length -eq 0 ]
    echo -ns $project_dir  # unnessary -s ?
    return
  end

  string replace -ar '(\.?[^/]{'"$theme_project_dir_length"'})[^/]*/' '$1/' $project_dir
end

function __dollar_git_ahead -S -d 'Print the ahead/behind state for the current branch'
  if [ "$theme_display_git_ahead_verbose" = 'yes' ]
    __dollar_git_ahead_verbose
    return
  end

  set -l ahead 0
  set -l behind 0
  for line in (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
    switch "$line"
      case '>*'
        if [ $behind -eq 1 ]
          echo '±'
          return
        end
        set ahead 1
      case '<*'
        if [ $ahead -eq 1 ]
          echo "$__dollar_git_plus_minus_glyph"
          return
        end
        set behind 1
    end
  end

  if [ $ahead -eq 1 ]
    echo "$__dollar_git_plus_glyph"
  else if [ $behind -eq 1 ]
    echo "$__dollar_git_minus_glyph"
  end
end

function __dollar_git_ahead_verbose -S -d 'Print a more verbose ahead/behind state for the current branch'
  set -l commits (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
  [ $status != 0 ]; and return

  set -l behind (count (for arg in $commits; echo $arg; end | command grep '^<'))
  set -l ahead (count (for arg in $commits; echo $arg; end | command grep -v '^<'))

  switch "$ahead $behind"
    case '' # no upstream
    case '0 0' # equal to upstream
      return
    case '* 0' # ahead of upstream
      echo "$__dollar_git_ahead_glyph$ahead"
    case '0 *' # behind upstream
      echo "$__dollar_git_behind_glyph$behind"
    case '*' # diverged from upstream
      echo "$__dollar_git_ahead_glyph$ahead$__dollar_git_behind_glyph$behind"
  end
end


# ==============================
# Segment functions
# ==============================

function __dollar_start_segment -S -d 'Start a prompt segment'
  set -l bg $argv[1]
  set -e argv[1]
  set -l fg $argv[1]
  set -e argv[1]

  set_color normal # clear out anything bold or underline...
  set_color -b $bg $fg $argv

  switch "$__dollar_current_bg"
    case ''
      # If there's no background, just start one
      echo -ns ''  # ' '
    case "$bg"
      # If the background is already the same color, draw a separator
      echo -ns $__dollar_right_arrow_glyph  # ' '
    case '*'
      # otherwise, draw the end of the previous segment and the start of the next
      set_color $__dollar_current_bg
      echo -ns $__dollar_right_black_arrow_glyph  # ' '
      set_color $fg $argv
  end

  set __dollar_current_bg $bg
end

function __dollar_path_segment -S -a current_dir -d 'Display a shortened form of a directory'
  set -l segment_color $__color_path
  set -l segment_basename_color $__color_path_basename

  if not [ -w "$current_dir" ]
    set segment_color $__color_path_nowrite
    set segment_basename_color $__color_path_nowrite_basename
  end

  __dollar_start_segment $segment_color

  set -l directory
  set -l parent

  switch "$current_dir"
    case /
      set directory '/'
    case "$HOME"
      set directory '~'
    case '*'
      set parent    (__dollar_pretty_parent "$current_dir")
      set directory (__dollar_basename "$current_dir")
  end

  echo -ns $parent  # unnessary -s ?
  set_color -b $segment_basename_color
  echo -ns $directory  # ' '
end

function __dollar_finish_segments -S -d 'Close open prompt segments'
  if [ -n "$__dollar_current_bg" ]
    set_color normal
    set_color $__dollar_current_bg
    echo -ns $__dollar_right_black_arrow_glyph  # ' '
  end

  if [ "$theme_newline_cursor" = 'yes' ]
    echo -ens "\n"
    set_color $fish_color_autosuggestion
    if [ "$theme_powerline_fonts" = "no" ]
      echo -ns '> '
    else
      echo -ns "$__dollar_right_arrow_glyph "
    end
  else if [ "$theme_newline_cursor" = 'clean' ]
    echo -ens "\n"
  end

  set_color normal
  set __dollar_current_bg
end


# ==============================
# Status and input mode segments
# ==============================

function __dollar_prompt_status -S -a last_status -d 'Display flags for a non-zero exit status, root user, and background jobs'
  set -l nonzero
  set -l superuser
  set -l bg_jobs

  # Last exit was nonzero
  [ $last_status -ne 0 ]
    and set nonzero $__dollar_nonzero_exit_glyph

  # If superuser (uid == 0)
  #
  # Note that iff the current user is root and '/' is not writeable by root this
  # will be wrong. But I can't think of a single reason that would happen, and
  # this way is 99.5% faster to check it this way, so that's a tradeoff I'm
  # willing to make.
  [ -w / ]
    and [ (id -u) -eq 0 ]
    and set superuser $__dollar_superuser_glyph

  # Jobs display
  jobs -p >/dev/null
    and set bg_jobs $__dollar_bg_job_glyph

  if [ "$nonzero" -o "$superuser" -o "$bg_jobs" ]
    __dollar_start_segment $__color_initial_segment_exit
    if [ "$nonzero" ]
      set_color normal
      set_color -b $__color_initial_segment_exit
      if [ "$theme_show_exit_status" = 'yes' ]
        echo -ns $last_status ' '
      else
        echo -ns $__dollar_nonzero_exit_glyph  # unnessary -s ?
      end
    end

    if [ "$superuser" ]
      set_color normal
      if [ -z "$FAKEROOTKEY" ]
        set_color -b $__color_initial_segment_su
      else
        set_color -b $__color_initial_segment_exit
      end

      echo -ns $__dollar_superuser_glyph  # unnessary -s ?
    end

    if [ "$bg_jobs" ]
      set_color normal
      set_color -b $__color_initial_segment_jobs
      echo -ns $__dollar_bg_job_glyph  # unnessary -s ?
    end
  end
end

function __dollar_prompt_vi -S -d 'Display vi mode'
  [ "$theme_display_vi" != 'no' ]; or return
  [ "$fish_key_bindings" = 'fish_vi_key_bindings' \
    -o "$fish_key_bindings" = 'hybrid_bindings' \
    -o "$fish_key_bindings" = 'fish_hybrid_key_bindings' \
    -o "$theme_display_vi" = 'yes' ]; or return
  switch $fish_bind_mode
    case default
      __dollar_start_segment $__color_vi_mode_default
      echo -n 'N '
    case insert
      __dollar_start_segment $__color_vi_mode_insert
      echo -n 'I '
    case replace_one replace-one
      __dollar_start_segment $__color_vi_mode_insert
      echo -n 'R '
    case visual
      __dollar_start_segment $__color_vi_mode_visual
      echo -n 'V '
  end
end


# ==============================
# Container and VM segments
# ==============================

function __dollar_prompt_vagrant -S -d 'Display Vagrant status'
  [ "$theme_display_vagrant" = 'yes' -a -f Vagrantfile ]; or return

  # .vagrant/machines/$machine/$provider/id
  for file in .vagrant/machines/*/*/id
    read -l id <"$file"

    if [ -n "$id" ]
      switch "$file"
        case '*/virtualbox/id'
          __dollar_prompt_vagrant_vbox $id
        case '*/vmware_fusion/id'
          __dollar_prompt_vagrant_vmware $id
        case '*/parallels/id'
          __dollar_prompt_vagrant_parallels $id
      end
    end
  end
end

function __dollar_prompt_vagrant_vbox -S -a id -d 'Display VirtualBox Vagrant status'
  set -l vagrant_status
  set -l vm_status (VBoxManage showvminfo --machinereadable $id ^/dev/null | command grep 'VMState=' | tr -d '"' | cut -d '=' -f 2)
  switch "$vm_status"
    case 'running'
      set vagrant_status "$vagrant_status$__dollar_vagrant_running_glyph"
    case 'poweroff'
      set vagrant_status "$vagrant_status$__dollar_vagrant_poweroff_glyph"
    case 'aborted'
      set vagrant_status "$vagrant_status$__dollar_vagrant_aborted_glyph"
    case 'saved'
      set vagrant_status "$vagrant_status$__dollar_vagrant_saved_glyph"
    case 'stopping'
      set vagrant_status "$vagrant_status$__dollar_vagrant_stopping_glyph"
    case ''
      set vagrant_status "$vagrant_status$__dollar_vagrant_unknown_glyph"
  end
  [ -z "$vagrant_status" ]; and return

  __dollar_start_segment $__color_vagrant
  echo -ns $vagrant_status ' '
end

function __dollar_prompt_vagrant_vmware -S -a id -d 'Display VMWare Vagrant status'
  set -l vagrant_status
  if [ (pgrep -f "$id") ]
    set vagrant_status "$vagrant_status$__dollar_vagrant_running_glyph"
  else
    set vagrant_status "$vagrant_status$__dollar_vagrant_poweroff_glyph"
  end
  [ -z "$vagrant_status" ]; and return

  __dollar_start_segment $__color_vagrant
  echo -ns $vagrant_status ' '
end

function __dollar_prompt_vagrant_parallels -S -d 'Display Parallels Vagrant status'
  set -l vagrant_status
  set -l vm_status (prlctl list $id -o status ^/dev/null | command tail -1)
  switch "$vm_status"
    case 'running'
      set vagrant_status "$vagrant_status$__dollar_vagrant_running_glyph"
    case 'stopped'
      set vagrant_status "$vagrant_status$__dollar_vagrant_poweroff_glyph"
    case 'paused'
      set vagrant_status "$vagrant_status$__dollar_vagrant_saved_glyph"
    case 'suspended'
      set vagrant_status "$vagrant_status$__dollar_vagrant_saved_glyph"
    case 'stopping'
      set vagrant_status "$vagrant_status$__dollar_vagrant_stopping_glyph"
    case ''
      set vagrant_status "$vagrant_status$__dollar_vagrant_unknown_glyph"
  end
  [ -z "$vagrant_status" ]; and return

  __dollar_start_segment $__color_vagrant
  echo -ns $vagrant_status ' '
end

function __dollar_prompt_docker -S -d 'Display Docker machine name'
  [ "$theme_display_docker_machine" = 'no' -o -z "$DOCKER_MACHINE_NAME" ]; and return
  __dollar_start_segment $__color_vagrant
  echo -ns $DOCKER_MACHINE_NAME ' '
end

function __dollar_prompt_k8s_context -S -d 'Show current Kubernetes context'
  [ "$theme_display_k8s_context" = 'no' ]; and return

  set -l config_paths "$HOME/.kube/config"
  [ -n "$KUBECONFIG" ]
    and set config_paths (string split ':' "$KUBECONFIG") $config_paths

  for file in $config_paths
    [ -f "$file" ]; or continue

    while read -l key val
      if [ "$key" = 'current-context:' ]
        set -l context (string trim -c '"\' ' -- $val)
        [ -z "$context" ]; and return

        __dollar_start_segment $__color_k8s
        echo -ns $context ' '
        return
      end
    end < $file
  end
end


# ==============================
# User / hostname info segments
# ==============================

function __dollar_prompt_user -S -d 'Display current user and hostname'
  [ "$theme_display_user" = 'yes' -o -n "$SSH_CLIENT" -o \( -n "$default_user" -a "$USER" != "$default_user" \) ]
    and set -l display_user
  [ "$theme_display_hostname" = 'yes' -o -n "$SSH_CLIENT" ]
    and set -l display_hostname

  if set -q display_user
    __dollar_start_segment $__color_username
    echo -ns (whoami)
  end

  if set -q display_hostname
    set -l IFS .
    hostname | read -l hostname __
    if set -q display_user
      # reset colors without starting a new segment...
      # (so we can have a bold username and non-bold hostname)
      set_color normal
      set_color -b $__color_hostname[1] $__color_hostname[2..-1]
      echo -ns '@' $hostname
    else
      __dollar_start_segment $__color_hostname
      echo -ns $hostname
    end
  end

  set -q display_user
    or set -q display_hostname
    and echo -ns ' '
end


# ==============================
# Virtual environment segments
# ==============================

function __dollar_rvm_parse_ruby -S -a ruby_string scope -d 'Parse RVM Ruby string'
  # Function arguments:
  # - 'ruby-2.2.3@rails', 'jruby-1.7.19'...
  # - 'default' or 'current'
  set -l IFS @
  echo "$ruby_string" | read __ruby __rvm_{$scope}_ruby_gemset __
  set IFS -
  echo "$__ruby" | read __rvm_{$scope}_ruby_interpreter __rvm_{$scope}_ruby_version __
  set -e __ruby
  set -e __
end

function __dollar_rvm_info -S -d 'Current Ruby information from RVM'
  # More `sed`/`grep`/`cut` magic...
  set -l __rvm_default_ruby (grep GEM_HOME ~/.rvm/environments/default | sed -e"s/'//g" | sed -e's/.*\///')
  set -l __rvm_current_ruby (rvm-prompt i v g)
  [ "$__rvm_default_ruby" = "$__rvm_current_ruby" ]; and return

  set -l __rvm_default_ruby_gemset
  set -l __rvm_default_ruby_interpreter
  set -l __rvm_default_ruby_version
  set -l __rvm_current_ruby_gemset
  set -l __rvm_current_ruby_interpreter
  set -l __rvm_current_ruby_version

  # Parse default and current Rubies to global variables
  __dollar_rvm_parse_ruby $__rvm_default_ruby default
  __dollar_rvm_parse_ruby $__rvm_current_ruby current
  # Show unobtrusive RVM prompt

  # If interpreter differs form default interpreter, show everything:
  if [ "$__rvm_default_ruby_interpreter" != "$__rvm_current_ruby_interpreter" ]
    if [ "$__rvm_current_ruby_gemset" = 'global' ]
      rvm-prompt i v
    else
      rvm-prompt i v g
    end
  # If version differs form default version
  else if [ "$__rvm_default_ruby_version" != "$__rvm_current_ruby_version" ]
    if [ "$__rvm_current_ruby_gemset" = 'global' ]
      rvm-prompt v
    else
      rvm-prompt v g
    end
  # If gemset differs form default or 'global' gemset, just show it
  else if [ "$__rvm_default_ruby_gemset" != "$__rvm_current_ruby_gemset" ]
    rvm-prompt g
  end
end

function __dollar_prompt_rubies -S -d 'Display current Ruby information'
  [ "$theme_display_ruby" = 'no' ]; and return

  set -l ruby_version
  if type -q rvm-prompt
    set ruby_version (__dollar_rvm_info)
  else if type -q rbenv
    set ruby_version (rbenv version-name)
    # Don't show global ruby version...
    set -q RBENV_ROOT
      or set -l RBENV_ROOT $HOME/.rbenv

    [ -e "$RBENV_ROOT/version" ]
      and read -l global_ruby_version <"$RBENV_ROOT/version"

    [ "$global_ruby_version" ]
      or set -l global_ruby_version system

    [ "$ruby_version" = "$global_ruby_version" ]; and return
  else if type -q chruby
    set ruby_version $RUBY_VERSION
  else if type -q asdf
    asdf current ruby ^/dev/null | read -l asdf_ruby_version asdf_provenance
      or return

    # If asdf changes their ruby version provenance format, update this to match
    [ "$asdf_provenance" = "(set by $HOME/.tool-versions)" ]; and return

    set ruby_version $asdf_ruby_version
  end
  [ -z "$ruby_version" ]; and return
  __dollar_start_segment $__color_rvm
  echo -ns $__dollar_ruby_glyph $ruby_version ' '
end

function __dollar_virtualenv_python_version -S -d 'Get current Python version'
  switch (python --version ^| tr '\n' ' ')
    case 'Python 2*PyPy*'
      echo $__dollar_pypy_glyph
    case 'Python 3*PyPy*'
      echo -s $__dollar_pypy_glyph $__dollar_superscript_glyph[3]
    case 'Python 2*'
      echo $__dollar_superscript_glyph[2]
    case 'Python 3*'
      echo $__dollar_superscript_glyph[3]
  end
end

function __dollar_prompt_virtualfish -S -d "Display current Python virtual environment (only for virtualfish, virtualenv's activate.fish changes prompt by itself)"
  [ "$theme_display_virtualenv" = 'no' -o -z "$VIRTUAL_ENV" ]; and return
  set -l version_glyph (__dollar_virtualenv_python_version)
  if [ "$version_glyph" ]
    __dollar_start_segment $__color_virtualfish
    echo -ns $__dollar_virtualenv_glyph $version_glyph ' '
  end
  echo -ns (basename "$VIRTUAL_ENV") ' '
end

function __dollar_prompt_virtualgo -S -d 'Display current Go virtual environment'
  [ "$theme_display_virtualgo" = 'no' -o -z "$VIRTUALGO" ]; and return
  __dollar_start_segment $__color_virtualgo
  echo -ns $__dollar_go_glyph
  echo -ns (basename "$VIRTUALGO") ' '
  set_color normal
end


# ==============================
# VCS segments
# ==============================

function __dollar_prompt_hg -S -a current_dir -d 'Display the actual hg state'
  set -l dirty (command hg stat; or echo -n '*')

  set -l flags "$dirty"
  [ "$flags" ]
    and set flags ""

  set -l flag_colors $__color_repo
  if [ "$dirty" ]
    set flag_colors $__color_repo_dirty
  end

  __dollar_path_segment $current_dir

  __dollar_start_segment $flag_colors
  echo -ns $__dollar_hg_glyph ' '

  __dollar_start_segment $flag_colors
  echo -ns (__dollar_hg_branch) $flags ' '
  set_color normal

  set -l project_pwd  (__dollar_project_pwd $current_dir)
  if [ "$project_pwd" ]
    if [ -w "$PWD" ]
      __dollar_start_segment $__color_path
    else
      __dollar_start_segment $__color_path_nowrite
    end

    echo -ns $project_pwd ' '
  end
end

function __dollar_prompt_git -S -a current_dir -d 'Display the actual git state'
  set -l dirty ''
  if [ "$theme_display_git_dirty" != 'no' ]
    set -l show_dirty (command git config --bool bash.showDirtyState ^/dev/null)
    if [ "$show_dirty" != 'false' ]
      set dirty (command git diff --no-ext-diff --quiet --exit-code ^/dev/null; or echo -ns "$__dollar_git_dirty_glyph")  # unnessary -s ?
    end
  end

  set -l staged  (command git diff --cached --no-ext-diff --quiet --exit-code ^/dev/null; or echo -ns "$__dollar_git_staged_glyph")  # unnessary -s ?
  set -l stashed (command git rev-parse --verify --quiet refs/stash >/dev/null; and echo -ns "$__dollar_git_stashed_glyph")  # unnessary -s ?
  set -l ahead   (__dollar_git_ahead)

  set -l new ''
  if [ "$theme_display_git_untracked" != 'no' ]
    set -l show_untracked (command git config --bool bash.showUntrackedFiles ^/dev/null)
    if [ "$show_untracked" != 'false' ]
      set new (command git ls-files --other --exclude-standard --directory --no-empty-directory ^/dev/null)
      if [ "$new" ]
        set new "$__dollar_git_untracked_glyph"
      end
    end
  end

  set -l flags "$dirty$staged$stashed$ahead$new"
  [ "$flags" ]
    and set flags " $flags"  # whether to add space here: ~/w/p/dollar-fishmaster(!)*/...

  set -l flag_colors $__color_repo
  if [ "$dirty" ]
    set flag_colors $__color_repo_dirty
  else if [ "$staged" ]
    set flag_colors $__color_repo_staged
  end

  __dollar_path_segment $current_dir

  __dollar_start_segment $flag_colors
  echo -ns (__dollar_git_branch) $flags  # ' '
  set_color normal

  if [ "$theme_git_worktree_support" != 'yes' ]
    set -l project_pwd (__dollar_project_pwd $current_dir)
    if [ "$project_pwd" ]
      if [ -w "$PWD" ]
        __dollar_start_segment $__color_path
      else
        __dollar_start_segment $__color_path_nowrite
      end

      echo -ns '/' $project_pwd  # ' '  # no space after project working directory
    end
    return
  end

  set -l project_pwd (command git rev-parse --show-prefix ^/dev/null | string trim --right --chars=/)
  set -l work_dir (command git rev-parse --show-toplevel ^/dev/null)

  # only show work dir if it's a parent…
  if [ "$work_dir" ]
    switch $PWD/
      case $work_dir/\*
        string match "$current_dir*" $work_dir >/dev/null
          and set work_dir (string sub -s (math 1 + (string length $current_dir)) $work_dir)
      case \*
        set -e work_dir
    end
  end

  if [ "$project_pwd" -o "$work_dir" ]
    set -l colors $__color_path
    if not [ -w "$PWD" ]
      set colors $__color_path_nowrite
    end

    __dollar_start_segment $colors

    # handle work_dir != project dir
    if [ "$work_dir" ]
      set -l work_parent (__dollar_dirname $work_dir)
      if [ "$work_parent" ]
        echo -ns "$work_parent/"  # unnessary -s ?
      end
      set_color normal
      set_color -b $__color_repo_work_tree
      echo -ns (__dollar_basename $work_dir)  # unnessary -s ?
      set_color normal
      set_color -b $colors
      [ "$project_pwd" ]
        and echo -ns '/'  # unnessary -s ?
    end

    echo -ns $project_pwd  # ' '
  else
    set project_pwd $PWD
    string match "$current_dir*" $project_pwd >/dev/null
      and set project_pwd (string sub -s (math 1 + (string length $current_dir)) $project_pwd)
    set project_pwd (string trim --left --chars=/ -- $project_pwd)

    if [ "$project_pwd" ]
      set -l colors $__color_path
      if not [ -w "$PWD" ]
        set colors $__color_path_nowrite
      end

      __dollar_start_segment $colors

      echo -ns $project_pwd  # ' '
    end
  end
end

function __dollar_prompt_dir -S -d 'Display a shortened form of the current directory'
  __dollar_path_segment "$PWD"
end


# ==============================
# Debugging functions
# ==============================

function __dollar_display_colors -d 'Print example prompts using the current color scheme'
  set -g __dollar_display_colors
end

function __dollar_maybe_display_colors -S
  set -q __dollar_display_colors; or return
  set -e __dollar_display_colors

  echo
  set_color normal

  __dollar_start_segment $__color_initial_segment_exit
  echo -n exit '! '
  set_color -b $__color_initial_segment_su
  echo -n su '$ '
  set_color -b $__color_initial_segment_jobs
  echo -n jobs '% '
  __dollar_finish_segments
  set_color normal
  echo -n "(<- initial_segment)"
  echo

  __dollar_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_path_nowrite
  echo -n /color/path/nowrite/
  set_color -b $__color_path_nowrite_basename
  echo -ns basename ' '
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __dollar_start_segment $__color_repo
  echo -n "$__dollar_branch_glyph repo $__dollar_git_stashed_glyph "
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __dollar_start_segment $__color_repo_dirty
  echo -n "$__dollar_tag_glyph repo_dirty $__dollar_git_dirty_glyph "
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __dollar_start_segment $__color_repo_staged
  echo -n "$__dollar_detached_glyph repo_staged $__dollar_git_staged_glyph "
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_vi_mode_default
  echo -ns vi_mode_default ' '
  __dollar_finish_segments
  __dollar_start_segment $__color_vi_mode_insert
  echo -ns vi_mode_insert ' '
  __dollar_finish_segments
  __dollar_start_segment $__color_vi_mode_visual
  echo -ns vi_mode_visual ' '
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_vagrant
  echo -ns $__dollar_vagrant_running_glyph ' ' vagrant ' '
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_username
  echo -n username
  set_color normal
  set_color -b $__color_hostname[1] $__color_hostname[2..-1]
  echo -ns @hostname ' '
  __dollar_finish_segments
  echo

  __dollar_start_segment $__color_rvm
  echo -ns $__dollar_ruby_glyph rvm ' '
  __dollar_finish_segments

  __dollar_start_segment $__color_virtualfish
  echo -ns $__dollar_virtualenv_glyph virtualfish ' '
  __dollar_finish_segments

  __dollar_start_segment $__color_virtualgo
  echo -ns $__dollar_go_glyph virtualgo ' '
  __dollar_finish_segments

  echo -e "\n"

end




# =============
# Cmd Duration
# =============
function __dollar_cmd_duration -S -d 'Show command duration'
  [ "$theme_display_cmd_duration" = "no" ]; and return
  [ -z "$CMD_DURATION" -o "$CMD_DURATION" -lt 100 ]; and return

  if [ "$CMD_DURATION" -lt 5000 ]
    echo -ns $CMD_DURATION 'ms'
  else if [ "$CMD_DURATION" -lt 60000 ]
    __dollar_pretty_ms $CMD_DURATION s
  else if [ "$CMD_DURATION" -lt 3600000 ]
    set_color $fish_color_error
    __dollar_pretty_ms $CMD_DURATION m
  else
    set_color $fish_color_error
    __dollar_pretty_ms $CMD_DURATION h
  end

  set_color $fish_color_normal
  set_color $fish_color_autosuggestion

  [ "$theme_display_date" = "no" ]
    or echo -ns ' ' $__dollar_left_arrow_glyph
end

function __dollar_pretty_ms -S -a ms interval -d 'Millisecond formatting for humans'
  set -l interval_ms
  set -l scale 1

  switch $interval
    case s
      set interval_ms 1000
    case m
      set interval_ms 60000
    case h
      set interval_ms 3600000
      set scale 2
  end

  switch $FISH_VERSION
    # Fish 2.3 and lower doesn't know about the -s argument to math.
    case 2.0.\* 2.1.\* 2.2.\* 2.3.\*
      math "scale=$scale;$ms/$interval_ms" | string replace -r '\\.?0*$' $interval
    case \*
      math -s$scale "$ms/$interval_ms" | string replace -r '\\.?0*$' $interval
  end
end

# ==========
# Timestamp
# ==========
function __dollar_timestamp -S -d 'Show the current timestamp'
  [ "$theme_display_date" = "no" ]; and return
  set -q theme_date_format
    or set -l theme_date_format "+%c"

  echo -n ' '
  date $theme_date_format
end

# ==============================
# Apply theme
# ==============================

function fish_right_prompt -d 'dollar is all about the right prompt'
  # Cmd Duration
  set -l __dollar_left_arrow_glyph '⟨'
  #if [ "$theme_powerline_fonts" = "no" ]
  #  set __dollar_left_arrow_glyph '⟨'
  #end
  set_color $fish_color_autosuggestion

  __dollar_cmd_duration
  #__dollar_timestamp
  set_color normal


  # Save the last status for later (do this before the `set` calls below)
  set -l last_status $status

  # Powerline glyphs
  set -l __dollar_branch_glyph            \uE0A0
  set -l __dollar_right_black_arrow_glyph ''  # \uE0B0
  set -l __dollar_right_arrow_glyph       ''  # \uE0B1
  set -l __dollar_left_black_arrow_glyph  ''  # \uE0B2
  set -l __dollar_left_arrow_glyph        ''  # \uE0B3

  # Additional glyphs
  set -l __dollar_detached_glyph          \u27A6
  set -l __dollar_tag_glyph               \u2302
  set -l __dollar_nonzero_exit_glyph      '! '
  set -l __dollar_superuser_glyph         '$ '
  set -l __dollar_bg_job_glyph            '% '
  set -l __dollar_hg_glyph                \u263F

  # Python glyphs
  set -l __dollar_superscript_glyph       \u00B9 \u00B2 \u00B3
  set -l __dollar_virtualenv_glyph        \u25F0
  set -l __dollar_pypy_glyph              \u1D56

  set -l __dollar_ruby_glyph              ''
  set -l __dollar_go_glyph                ''

  # Vagrant glyphs
  set -l __dollar_vagrant_running_glyph   \u2191 # ↑ 'running'
  set -l __dollar_vagrant_poweroff_glyph  \u2193 # ↓ 'poweroff'
  set -l __dollar_vagrant_aborted_glyph   \u2715 # ✕ 'aborted'
  set -l __dollar_vagrant_saved_glyph     \u21E1 # ⇡ 'saved'
  set -l __dollar_vagrant_stopping_glyph  \u21E3 # ⇣ 'stopping'
  set -l __dollar_vagrant_unknown_glyph   '!'    # strange cases

  # Git glyphs
  set -l __dollar_git_dirty_glyph      '*'
  set -l __dollar_git_staged_glyph     '~'
  set -l __dollar_git_stashed_glyph    '$'
  set -l __dollar_git_untracked_glyph  '…'
  set -l __dollar_git_ahead_glyph      \u2191 # '↑'
  set -l __dollar_git_behind_glyph     \u2193 # '↓'
  set -l __dollar_git_plus_glyph       '+'
  set -l __dollar_git_minus_glyph      '-'
  set -l __dollar_git_plus_minus_glyph '±'

  # Disable Powerline fonts
  if [ "$theme_powerline_fonts" = "no" ]
    set __dollar_branch_glyph            \u2387  # ⎇
    set __dollar_right_black_arrow_glyph ''
    set __dollar_right_arrow_glyph       ''
    set __dollar_left_black_arrow_glyph  ''
    set __dollar_left_arrow_glyph        ''
  end

  # Use prettier Nerd Fonts glyphs
  if [ "$theme_nerd_fonts" = "yes" ]
    set __dollar_branch_glyph     \uF418
    set __dollar_detached_glyph   \uF417
    set __dollar_tag_glyph        \uF412

    set __dollar_virtualenv_glyph \uE73C ' '
    set __dollar_ruby_glyph       \uE791 ' '
    set __dollar_go_glyph         \uE626 ' '

    set __dollar_vagrant_running_glyph  \uF431 # ↑ 'running'
    set __dollar_vagrant_poweroff_glyph \uF433 # ↓ 'poweroff'
    set __dollar_vagrant_aborted_glyph  \uF468 # ✕ 'aborted'
    set __dollar_vagrant_unknown_glyph  \uF421 # strange cases

    set __dollar_git_dirty_glyph      \uF448 '' # nf-oct-pencil
    set __dollar_git_staged_glyph     \uF0C7 '' # nf-fa-save
    set __dollar_git_stashed_glyph    \uF0C6 '' # nf-fa-paperclip
    set __dollar_git_untracked_glyph  \uF128 '' # nf-fa-question
    # set __dollar_git_untracked_glyph  \uF141 '' # nf-fa-ellipsis_h

    set __dollar_git_ahead_glyph      \uF47B # nf-oct-chevron_up
    set __dollar_git_behind_glyph     \uF47C # nf-oct-chevron_down

    set __dollar_git_plus_glyph       \uF0DE # fa-sort-asc
    set __dollar_git_minus_glyph      \uF0DD # fa-sort-desc
    set __dollar_git_plus_minus_glyph \uF0DC # fa-sort
  end

  # Avoid ambiguous glyphs
  if [ "$theme_avoid_ambiguous_glyphs" = "yes" ]
    set __dollar_git_untracked_glyph '...'
  end


  # Colors

  switch "$theme_color_scheme"
    case 'user'
      # Do not set any variables in this section.

      # If you want to create your own color scheme, set `theme_color_scheme` to
      # `user` and define the `__color_*` variables listed below in your fish
      # startup file (`$OMF_CONFIG/init.fish`, or similar).

      # The value for each variable is an argument to pass to `set_color -b`.
      # You can copy the commented code below as a base for your custom colors.
      # Use `__dollar_display_colors` at the command line to easily see what
      # these variables are used for.

      # See the built-in color schemes below for more examples.

      # # Example dollar color scheme:
      # set -g theme_color_scheme user
      #
      # set -g __color_initial_segment_exit  ffffff ce000f --bold
      # set -g __color_initial_segment_su    ffffff 189303 --bold
      # set -g __color_initial_segment_jobs  ffffff 255e87 --bold
      #
      # set -g __color_path                  333333 999999
      # set -g __color_path_basename         333333 ffffff --bold
      # set -g __color_path_nowrite          660000 cc9999
      # set -g __color_path_nowrite_basename 660000 cc9999 --bold
      #
      # set -g __color_repo                  addc10 0c4801
      # set -g __color_repo_work_tree        333333 ffffff --bold
      # set -g __color_repo_dirty            ce000f ffffff
      # set -g __color_repo_staged           f6b117 3a2a03
      #
      # set -g __color_vi_mode_default       999999 333333 --bold
      # set -g __color_vi_mode_insert        189303 333333 --bold
      # set -g __color_vi_mode_visual        f6b117 3a2a03 --bold
      #
      # set -g __color_vagrant               48b4fb ffffff --bold
      # set -g __color_username              cccccc 255e87 --bold
      # set -g __color_hostname              cccccc 255e87
      # set -g __color_rvm                   af0000 cccccc --bold
      # set -g __color_virtualfish           005faf cccccc --bold
      # set -g __color_virtualgo             005faf cccccc --bold

    case '*' # default dark theme
      #               light  medium dark
      #               ------ ------ ------
      set -l red      cc9999 ce000f 660000
      set -l green    addc10 189303 0c4801
      set -l blue     48b4fb 005faf 255e87
      set -l orange   f6b117 unused 3a2a03
      set -l brown    bf5e00 803f00 4d2600
      set -l grey     cccccc 999999 333333
      set -l white    ffffff eeeeee dddddd
      set -l black    000000
      set -l ruby_red af0000

      set __color_initial_segment_exit     $white[1] $red[2] --bold
      set __color_initial_segment_su       $white[1] $green[2] --bold
      set __color_initial_segment_jobs     $white[1] $blue[3] --bold

      set __color_path                     $grey[3] $grey[2]
      set __color_path_basename            $grey[3] $white[3] --bold # $grey[3] $white[1] --bold
      set __color_path_nowrite             $red[3] $red[1]
      set __color_path_nowrite_basename    $red[3] $red[1] --bold

      set __color_repo                     $grey[3] $green[1] # $green[1] $green[3]
      set __color_repo_work_tree           $grey[3] $grey[1] # $grey[3] $white[1] --bold
      set __color_repo_dirty               $grey[3] $red[2] # $red[2] $white[1]
      set __color_repo_staged              $grey[3] $orange[1] # $orange[1] $orange[3]

      set __color_vi_mode_default          $grey[2] $grey[3] --bold
      set __color_vi_mode_insert           $green[2] $grey[3] --bold
      set __color_vi_mode_visual           $orange[1] $orange[3] --bold

      set __color_vagrant                  $blue[1] $white[1] --bold
      set __color_k8s                      $green[2] $white[1] --bold
      set __color_username                 $grey[1] $blue[3] --bold
      set __color_hostname                 $grey[1] $blue[3]
      set __color_rvm                      $ruby_red $grey[1] --bold
      set __color_virtualfish              $blue[2] $grey[1] --bold
      set __color_virtualgo                $blue[2] $grey[1] --bold
  end

  # Start each line with a blank slate
  set -l __dollar_current_bg

  # Internal: used for testing color schemes
  __dollar_maybe_display_colors

  # Status flags and input mode
  __dollar_prompt_status $last_status  # TODO: alter.
  __dollar_prompt_vi

  # Containers and VMs
  __dollar_prompt_vagrant
  __dollar_prompt_docker
  __dollar_prompt_k8s_context

  # User / hostname info
  __dollar_prompt_user

  # Virtual environments
  __dollar_prompt_rubies
  __dollar_prompt_virtualfish
  __dollar_prompt_virtualgo

  # VCS
  set -l git_root (__dollar_git_project_dir)
  set -l hg_root  (__dollar_hg_project_dir)

  # Git
  if [ "$git_root" -a "$hg_root" ]
    # only show the closest parent
    switch $git_root
      case $hg_root\*
        __dollar_prompt_git $git_root
      case \*
        __dollar_prompt_hg $hg_root
    end
  else if [ "$git_root" ]
    __dollar_prompt_git $git_root
  else if [ "$hg_root" ]
    __dollar_prompt_hg $hg_root
  else
    __dollar_prompt_dir
  end

  __dollar_finish_segments
end
