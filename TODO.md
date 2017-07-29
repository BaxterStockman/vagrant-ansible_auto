# TODO

- See if it possible to Vagrant::Util::IsPortOpen instead of Bash/nc/etc for
  checking whether a port is open.  *Has to run on the guest*, so probably not
  possible.
- Util::ScopedHashOverride for the key conversions done in Host?
- Util::HashWithIndifferentAccess for Host?
- default vaues for arguments to attr_writer methods in `Inventory`
- Make sure error messages use `channel: :error`
- Safe method for expansion of remote paths
- Check that the version of Ansible on the control machine supports the `local`
  connection type
- (Optionally) remove inventory host private keys from the control machine
  after `ansible-playbook` runs
- Delegate config methods `groups=`, `children=`, and `vars=` to the
  `inventory` instance variable (for auto-vivification of the various hashes)

## I1*8n

- Command line option usage
- Error message in `command/root.rb` (and any other instances of
  `@env.ui#method`)
