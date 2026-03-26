# matrix
Who needs something else?

# Nixos Setup

## Automatic Tests

Using the nixos framework, tests can be written and performed. See https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests

Perform all tests using `nix flake check`. Call a specific test using `nix build .#checks.x86_64-linux.test1`

## Testing the VM

The VM can be build using `nixos-rebuild build-vm --flake .#matrix` and started using `result/bin/run-nixos-vm`.

See also https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf

# Setup

## Nixos-Everywhere

## Secret Depolyment

The initial secret deployment needs to be performed manually, sadly ...