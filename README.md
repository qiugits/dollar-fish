# dollar

`dollar` is a Powerline-style, Git-aware [fish][fish] theme optimized for awesome.

[![Oh My Fish](https://img.shields.io/badge/Framework-Oh_My_Fish-blue.svg?style=flat)](https://github.com/oh-my-fish/oh-my-fish) [![MIT License](https://img.shields.io/github/license/oh-my-fish/theme-dollar.svg?style=flat)](/LICENSE.md)

![dollar][screencast]


### Installation

Be sure to have Fisherman installed. Then just:

    fisher qiugits/dollar-fish

This theme is based loosely on [bobthefish][bobthefish].


### Features

 * A helpful, but not too distracting, greeting.
 * Compact information on the right.
 * More colors than you know what to do with.
 * An abbreviated path which doesn't abbreviate the name of the current project.
 * All the things you need to know about Git in a glance.
 * Visual indication that you can't write to the current directory.


---
Below is basically not changed from bobthefish.


### The Prompt

 * Flags:
     * Previous command failed (**`!`**)
     * Background jobs (**`%`**)
     * You currently have superpowers (**`$`**)
     * Cursor on newline
 * Current vi mode
 * `User@Host` (unless you're the default user)
 * Current RVM, rbenv or chruby (Ruby) version
 * Current virtualenv (Python) version
     * _If you use virtualenv, you will probably need to disable the default virtualenv prompt, since it doesn't play nice with fish: `set -x VIRTUAL_ENV_DISABLE_PROMPT 1`_
 * Abbreviated parent directory
 * Current directory, or Git or Mercurial project name
 * Current project's repo branch (<img width="16" alt="branch-glyph" src="https://cloud.githubusercontent.com/assets/53660/8768360/53ee9b58-2e32-11e5-9977-cee0063936fa.png"> master) or detached head (`➦` d0dfd9b)
 * Git or Mercurial status, via colors and flags:
     * Dirty working directory (**`*`**)
     * Untracked files (**`…`**)
     * Staged changes (**`~`**)
     * Stashed changes (**`$`**)
     * Unpulled commits (**`-`**)
     * Unpushed commits (**`+`**)
     * Unpulled _and_ unpushed commits (**`±`**)
     * _Note that not all of these have been implemented for hg yet :)_
 * Abbreviated project-relative path


### Configuration

You can override some of the following default options in your `config.fish`:

```fish
set -g theme_display_git no
set -g theme_display_git_dirty no
set -g theme_display_git_untracked no
set -g theme_display_git_ahead_verbose yes
set -g theme_git_worktree_support yes
set -g theme_display_vagrant yes
set -g theme_display_docker_machine no
set -g theme_display_k8s_context yes
set -g theme_display_hg yes
set -g theme_display_virtualenv no
set -g theme_display_ruby no
set -g theme_display_user yes
set -g theme_display_hostname yes
set -g theme_display_vi no
set -g theme_display_date no
set -g theme_display_cmd_duration yes
set -g theme_title_display_process yes
set -g theme_title_display_path no
set -g theme_title_display_user yes
set -g theme_title_use_abbreviated_path no
set -g theme_date_format "+%a %H:%M"
set -g theme_avoid_ambiguous_glyphs yes
set -g theme_powerline_fonts no
set -g theme_nerd_fonts yes
set -g theme_show_exit_status yes
set -g default_user your_normal_user
set -g theme_color_scheme dark
set -g fish_prompt_pwd_dir_length 0
set -g theme_project_dir_length 1
set -g theme_newline_cursor yes
```

**Title options**

- `theme_title_display_process`. By default theme doesn't show current process name in terminal title. If you want to show it, just set to `yes`.
- `theme_title_display_path`. Use `no` to hide current working directory from title.
- `theme_title_display_user`. Set to `yes` to show the current user in the tab title (unless you're the default user).
- `theme_title_use_abbreviated_path`. Default is `yes`. This means your home directory will be displayed as `~` and `/usr/local` as `/u/local`. Set it to `no` if you prefer full paths in title.

**Prompt options**

- `theme_display_ruby`. Use `no` to completely hide all information about Ruby version. By default Ruby version displayed if there is the difference from default settings.
- `theme_display_vagrant`. This feature is disabled by default, use `yes` to display Vagrant status in your prompt. Please note that only the VirtualBox and VMWare providers are supported.
- `theme_display_vi`. By default the vi mode indicator will be shown if vi or hybrid key bindings are enabled. Use `no` to hide the indicator, or `yes` to show the indicator.
- `theme_display_k8s_context`. By default the current kubernetes context is shown (`> kubectl config current-context`). Use `no` to hide the context.
- `theme_show_exit_status`. Set this option to yes to have the prompt show the last exit code if it was non_zero instead of just the exclamation mark.
- `theme_git_worktree_support`. If you do any git worktree shenanigans, setting this to `yes` will fix incorrect project-relative path display. If you don't do any git worktree shenanigans, leave it disabled. It's faster this way :)
- `fish_prompt_pwd_dir_length`. dollar respects the Fish `$fish_prompt_pwd_dir_length` setting to abbreviate the prompt path. Set to `0` to show the full path, `1` (default) to show only the first character of each parent directory name, or any other number to show up to that many characters.
- `theme_project_dir_length`. The same as `$fish_prompt_pwd_dir_length`, but for the path relative to the current project root. Defaults to `0`; set to any other number to show an abbreviated path.
- `theme_newline_cursor`. Use `yes` to have cursor start on a new line. By default the prompt is only one line. When working with long directories it may be preferrend to have cursor on the next line. Setting this to `clean` instead of `yes` suppresses the caret on the new line.

**Color scheme options**
Finally, you can specify your very own color scheme by setting
`theme_color_scheme` to `user`. In that case, you also need to define some
variables to set the colors of the prompt. See the "Colors" section of
`fish_prompt.fish` for details.


**VCS options**
- `set -g theme_vcs_ignore_paths /some/path /some/other/path{foo,bar}`. Ignore project paths for Git or Mercurial. Supports glob patterns.

### Overrides

You can disable the theme default greeting, vi mode prompt, right prompt, or title entirely — or override with your own — by adding custom functions to `~/.config/fish/functions`:

- `~/.config/fish/functions/fish_greeting.fish`
- `~/.config/fish/functions/fish_mode_prompt.fish`
- `~/.config/fish/functions/fish_right_prompt.fish`
- `~/.config/fish/functions/fish_title.fish`

To disable them completely, use an empty function:

```fish
function fish_right_prompt; end
```

… Or copy one from your favorite theme, make up something of your own, or copy/paste a dollar default function and modify it to your taste!

```fish
function fish_greeting
  set_color $fish_color_autosuggestion
  echo "I'm completely operational, and all my circuits are functioning perfectly."
  set_color normal
end
```


[fish]:       https://github.com/fish-shell/fish-shell
[screencast]: https://raw.githubusercontent.com/qiugits/dollar-fish/screencast.png
[patching]:   https://powerline.readthedocs.org/en/master/installation.html#patched-fonts
[fonts]:      https://github.com/Lokaltog/powerline-fonts
[nerd-fonts]: https://github.com/ryanoasis/nerd-fonts
[bobthefish]: https://github.com/oh-my-fish/theme-bobthefish

[dark]:            https://cloud.githubusercontent.com/assets/53660/16141569/ee2bbe4a-3411-11e6-85dc-3d9b0226e833.png "dark"
[light]:           https://cloud.githubusercontent.com/assets/53660/16141570/f106afc6-3411-11e6-877d-fc2a8f6d3175.png "light"
[solarized]:       https://cloud.githubusercontent.com/assets/53660/16141572/f7724032-3411-11e6-8771-b43769e7afec.png "solarized"
[solarized-light]: https://cloud.githubusercontent.com/assets/53660/16141575/fbed8036-3411-11e6-92e9-90da6d45f94b.png "solarized-light"
[base16]:          https://cloud.githubusercontent.com/assets/53660/16141577/0134763a-3412-11e6-9cca-6040d39c8fd4.png "base16"
[base16-light]:    https://cloud.githubusercontent.com/assets/53660/16141579/02f7245e-3412-11e6-97c6-5f3cecffb73c.png "base16-light"
[zenburn]:         https://cloud.githubusercontent.com/assets/53660/16141580/06229dd4-3412-11e6-84aa-a48de127b6da.png "zenburn"
[terminal-dark]:   https://cloud.githubusercontent.com/assets/53660/16141583/0b3e8eea-3412-11e6-8068-617c5371f6ea.png "terminal-dark"
