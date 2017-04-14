# TODO

- See if it possible to Vagrant::Util::IsPortOpen instead of Bash/nc/etc for
  checking whether a port is open.  *Has to run on the guest*, so probably not
  possible.
- Util::ScopedHashOverride for the key conversions done in Host?
- Util::HashWithIndifferentAccess for Host?
- default vaues for arguments to attr_writer methods in `Inventory`
