### 24-07-2019 VERSION 0.5.6

- Fix issue where `cani` would crash when used without arguments. Original behavior of showing `cani help` in that case is restored. ([#14](../../pull/14))
- Disable FZF's preview window using `--no-preview` to override `FZF_DEFAULT_OPTS` ([#12](../../issues/12))

### 06-07-2019 VERSION 0.5.5

- Added ability to (permanently) toggle between enabling and disabling of automatic shell configuration injection

### 06-10-2018 VERSION 0.5.4

- Fixed issue where `system` prints the version of fzf before running the command.
- When multiple matches are found for a given query: `cani use shadow`, an fzf window will
  now be opened with results filtered by the text `shadow` as initial query string.

