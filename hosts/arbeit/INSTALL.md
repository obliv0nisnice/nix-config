# Installing `arbeit`

Takes a new machine from a plain NixOS install to this flake, then links
`/etc/nixos/flake.nix` to the repo so that rebuilds no longer need a path.

## 1. Install plain NixOS

Install from the NixOS ISO. Create the user **`jakob`**, because the flake
manages that user and expects the repo in its home directory. Reboot into the
new system.

## 2. Get the repo

The repo has to end up in `~/nix-config`: `nh`, the wallpapers and nixvim all
expect that path.

No SSH key is needed, the archive downloads from the public GitHub repo:

```bash
cd ~
nix-shell -p wget --run "wget -O nix-config.tar.gz https://github.com/obliv0nisnice/nix-config/archive/refs/heads/main.tar.gz"
tar xzf nix-config.tar.gz
mv nix-config-main nix-config
rm nix-config.tar.gz
cd ~/nix-config
```
## 3. Add the hardware config
```bash
nixos-generate-config --show-hardware-config > hosts/arbeit/hardware.nix
```

In `hosts/arbeit/default.nix`, replace `../default/hardware.nix` with
`./hardware.nix` and delete the TODO comment above it.

If you encrypted the disk, check for LUKS lines the installer put in
`configuration.nix`. It often puts encrypted swap there, and the generated file
won't contain it. Copy any lines this prints into `hosts/arbeit/host-packages.nix`:

```bash
grep -n 'boot.initrd.luks' /etc/nixos/configuration.nix
```

## 4. Check the GPU

```bash
nix-shell -p pciutils --run "lspci | grep -Ei 'vga|3d'"
```

`lspci` prints hex, Nix wants decimal: `00:02.0` is `PCI:0:2:0`.

- Only the Nvidia GPU listed, or a desktop using just that card: nothing to change.
- Laptop with both Intel and Nvidia GPUs: set `profile = "nvidia-laptop"` for `arbeit`
  in `flake.nix`, and set `intelID` and `nvidiaID` in `hosts/arbeit/variables.nix` to match.
- Very new Nvidia card? Add `hardware.nvidia.open = true;` to `hosts/arbeit/host-packages.nix`.

## 5. Build and reboot

If you used `git clone`, run `git add hosts/arbeit` first, because a flake in a
git repo only sees files git knows about. The wget copy doesn't need this.

```bash
sudo nixos-rebuild boot --flake ~/nix-config#arbeit
sudo reboot
```

The host name is passed explicitly here because the machine isn't called
`arbeit` until this generation boots. `boot` rather than `switch` avoids
replacing the running desktop mid-build. If it doesn't come up, pick the
previous generation in the boot menu.

## 6. Create the symlink

```bash
sudo ln -sfn /home/jakob/nix-config/flake.nix /etc/nixos/flake.nix
```

`nixos-rebuild` follows this link to the repo and picks the config matching the
host name, so `--flake` is no longer needed:

```bash
readlink -f /etc/nixos/flake.nix   # should print the repo path
sudo nixos-rebuild dry-build       # should evaluate arbeit
```

## Rebuilding from now on

```bash
sudo nixos-rebuild switch   # or the alias: fr
```

Use `fu` to update the flake inputs as well. Save `hosts/arbeit/hardware.nix`
somewhere outside this machine, for example by committing it from a real clone,
so the hardware config isn't lost.
