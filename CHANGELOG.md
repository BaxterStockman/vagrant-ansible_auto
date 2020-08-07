## Next Version (Unreleased)

FEATURES:

IMPROVEMENTS:

BUG FIXES:

- Add missing `require "simplecov"` to [`spec/spec_helper.rb`], correcting a
  fatal `NameError` referring to `SimpleCov`.

## 0.2.2 (August 23, 2017)

BUG FIXES:

- `vagrant ansible inventory --help` no longer prints an inventory after the
  help text
- `vagrant ansible --help` shows available subcommands rather than an `I18n`
  "translation missing" error message

## 0.2.1 (July 29, 2017)

BUG FIXES:

- Fix build errors by committing updated `Gemfile.lock` with version bump

## 0.2.1 (July 29, 2017)

FEATURES:

- Permit inserting the control machine's public key into the `authorized_keys`
  file on managed machines, as an alternative to uploading the managed
  machines' private keys to the control machine
- Add JSON output options to `vagrant ansible inventory`

IMPROVEMENTS:

- Add I18n support
