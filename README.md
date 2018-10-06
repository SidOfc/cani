# Cani &mdash; a [caniuse.com](caniuse.com) tui interface ![Licence](https://img.shields.io/badge/license-MIT-E9573F.svg) [![Gem Version](https://img.shields.io/gem/v/cani.svg?colorB=E9573F&style=square)](https://rubygems.org/gems/cani) [![Issues](https://img.shields.io/github/issues/SidOfc/cani.svg)](https://github.com/SidOfc/cani/issues)

![cani cli](/assets/cani.png)

Cani is a small command-line wrapper around the data of [caniuse](https://caniuse.com).
It uses [fzf](https://github.com/junegunn/fzf) and [curses](https://github.com/ruby/curses) to display results.
This wrapper aims to be easy to use out of the box. To achieve this it ships with completions
for `bash`, `fish`, and `zsh`. [Caniuse data (1.7MB)](https://github.com/Fyrd/caniuse/blob/master/data.json) is fetched and updated automatically
on a regular interval together with completions.

## Latest changes

### 06-10-2018 VERSION 0.5.4

- Fixed issue where `system` prints the version of fzf before running the command.
- When multiple matches are found for a given query: `cani use shadow`, an fzf window will
  now be opened with results filtered by the text `shadow` as initial query string.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cani'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cani

**dependencies**

Cani depends on [fzf](https://github.com/junegunn/fzf) to display most menu's.
<!-- Fzf is not a requirement when piping the output to another command -->

## Configuration

After installation, running the command (`cani`) for the first time will create some files and directories:

- `~/.config/cani/config.yml` - default configuration
- `~/.config/cani/caniuse.json` - caniuse api data
- `~/.config/cani/completions/_cani.bash` - bash completion
- `~/.config/cani/completions/_cani.zsh` - zsh completion
- `~/.config/fish/completions/cani.fish` - fish completions

Some existing files will also be modified:

- `~/.bashrc` - A source line to bash completions will be added, or updated if it exists
- `~/.zshrc` - A source line to zsh completions will be added, or updated if it exists

After running the command for the first time, please restart your shell or `source` your `~/.*rc` file to load completions.
There are some commented settings that can be adjusted in the `~/.config/cani/config.yml` file.

## Usage

Running `cani` without arguments yields the help description.
Cani supports the following actions:

- [`use [FEATURE]`](#use) - show browser support for selected feature
- [`show [BROWSER [VERSION]]`](#show) - show feature support based on selected browser / version
- [`help`](#help) - show help
- [`version`](#version) - print the version number
- [`update`](#update) - force update data and completions
- [`install_completions`](#install_completions) - install shell completions
- [`purge`](#purge) - purge files and directories created by `cani`
- [`edit`](#edit) - edit the default configuration file with `$EDITOR`

### use

```sh
cani use
```

Show a list of features with fzf. Features are shown with their current W3C status, percentage of support, title and
each individual browser's support on a single row.

This command may be invoked with a feature and supports <kbd>tab</kbd> completion in `bash`, `zsh` and `fish`:

```sh
cani use grid-layout

# or:
# cani use 'grid layout'
# cani use 'gridlayout'
```

The above command will show the following table:

![Cani use box-shadow support table](/assets/cani-feature-table.png)

The table is responsive and will show browsers that fit in available space, everything else wraps accordingly.
The current era has a light-black border. Browser versions with less than `0.5%` usage aren't shown.
At the bottom there is a legend that provides an abbreviated status color overview. Below that, additional notes can be found.
Notes are shown based on relevant and visible browsers, all other notes are hidden (this can be changed in the config).

If your display height is `<= 40` lines, era's will be displayed in a more compact manner while still allowing space for notes:

![Cani use box-shadow support table](/assets/cani-feature-table-compressed.png)

### show

```sh
cani show
```

Show a list of browsers. Selecting a browser will take you to the versions for that browser.
Selecting a version shows the final window with feature support for that specific browser version.
Navigating to the previous window is possible by pressing <kbd>escape</kbd>, this will move you up one level.
When <kbd>escape</kbd> is pressed at the browser selection menu, the command will exit.
Selecting a feature using <kbd>enter</kbd> will show you the **current** support table for that feature **regardless** of selected version.

This command may be invoked with a browser and / or version and supports <kbd>tab</kbd> completion in `bash`, `zsh` and `fish`:

```sh
# show all versions of chrome
cani show chr

# show all features with support level in chrome 70
cani show chr 70
```

### help

```sh
cani help
```

Displays short help for the `cani` command

### version

```sh
cani version
```

Displays the current version e.g: `0.1.0`

### update

```sh
cani update
```

Force update dataset and completions.

### install_completions

```sh
cani install_completions
```

Completions are supported for `zsh`, `bash` and `fish` shells (currently).
They are automatically installed upon first invocation of the `cani` command.
This command is only a fallback in case there were any issues with permissions etc..

### purge

```sh
cani purge
```

Purges all files created by this command, removing every trace except the executable itself.
It will also remove source lines added that pointed to the completions in `~/.zshrc` and `~/.bashrc`.
After running a `purge`, all that remains is running `gem uninstall cani` to completely purge it.

### edit

```sh
cani edit
```

Edit the configuration file located at `~/.config/cani/config.yml` using `$EDITOR` env variable.

## Pipe output

Last but not least, all `cani` commands can be piped. This will skip running `fzf` and print uncolored output.

**use** _(the output of_ `cani use ft-name` _cannot be piped)_
```sh
cani use | head -3
[rc]   97.11%   PNG alpha transparency       +chr   +ff   +edge   +ie   +saf   +saf.ios   +op   +and   +bb
[un]   75.85%   Animated PNG (APNG)          +chr   +ff   -edge   -ie   +saf   +saf.ios   +op   -and   -bb
[ls]   94.32%   Video element                +chr   +ff   +edge   +ie   +saf   +saf.ios   +op   +and   +bb
```

**show**
```sh
cani show | head -3
ie                       usage: 3.1899%
edge                     usage: 1.8262%
firefox                  usage: 5.0480%
```

**show BROWSER**
```sh
cani show firefox | head -3
63    usage: 0.0000%
62    usage: 0.0131%
61    usage: 0.2184%
```

**show BROWSER VERSION**
```sh
cani show firefox 63 | head -3
[rc]   [+]   PNG alpha transparency
[un]   [+]   Animated PNG (APNG)
[ls]   [+]   Video element
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sidofc/cani. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Special thanks to the following users and contributors:

- [DamienRobert](https://github.com/DamienRobert)
    - Enhance `fzf` executable [detection](https://github.com/SidOfc/cani/pull/3)
    - Pointing out that some texts were [unreadable](https://github.com/SidOfc/cani/issues/2) on light background terminals ([pull](https://github.com/SidOfc/cani/pull/4)).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cani project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/cani/blob/master/CODE_OF_CONDUCT.md).
