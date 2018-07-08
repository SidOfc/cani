# Cani

Cani is a small command-line wrapper around the data of [caniuse](https://caniuse.com).
It uses [fzf](https://github.com/junegunn/fzf) to display results.

![cani cli](/assets/cani.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cani'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cani

## Usage

After installing, the `cani` executable will be available to you.
Running `cani` without arguments yields the help description.
Cani supports the following actions:

- [`use`](#use) - show browser support for a feature
- [`show BROWSER VERSION`](#show) - show feature support based on selected browser / version
- [`help`](#help) - show help
- [`version`](#version) - print the version number
- [`update`](#update) - force update data and completions
- [`install_completions`](#install_completions) - install shell completions
- [`purge`](#purge) - purge files and directories created by `cani`

### use

```sh
cani use
```

Show a list of features with fzf. Features are shown with their current W3C status, percentage of support, title and
each individual browser's support on a single row.

### show

```sh
cani show
```

Show a list of browsers. Selecting a browser will take you to the versions for that browser.
Selecting a version shows the final window with feature support for that specific browser version.

This command can also be invoked directly with a browser and version:

```sh
# show all versions of chrome
cani show chr

# show all supported features in chrome 70
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
That needs to be uninstalled using `gem uninstall cani`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sidofc/cani. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cani project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/cani/blob/master/CODE_OF_CONDUCT.md).
