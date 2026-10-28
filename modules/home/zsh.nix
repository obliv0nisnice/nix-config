{pkgs, profile, username, host, ...}:{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = false;

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
      }
    ];

    initContent = ''
      pokefetch
      bindkey "\eh" backward-word
      bindkey "\ej" down-line-or-history
      bindkey "\ek" up-line-or-history
      bindkey "\el" forward-word
      PROMPT="%F{green}%n@%m%f ''${PROMPT}"

      typeset -gA FAST_HIGHLIGHT_STYLES
      FAST_HIGHLIGHT_STYLES[command]='fg=green'
      FAST_HIGHLIGHT_STYLES[builtin]='fg=green'
      FAST_HIGHLIGHT_STYLES[alias]='fg=green'
      FAST_HIGHLIGHT_STYLES[function]='fg=green'
      FAST_HIGHLIGHT_STYLES[precommand]='fg=green'
      FAST_HIGHLIGHT_STYLES[hashed-command]='fg=green'
    '';


    shellAliases = {
      remote-server-build = "nixos-server-rebuild switch \
  --flake /home/oblivion/Documents/Projects/NixOS-Config#homedepot \
  --target-host jakob@192.168.1.119 \
  --build-host localhost \
  --use-remote-sudo \
  --option extra-platforms x86_64-linux \
  --option extra-sandbox-paths /run/binfmt";
      os-rebuild = "sudo nixos-rebuild switch --flake /home/${username}/nix-config/#${host} --impure";
      wg-on = "sudo wg-quick up /home/${username}/Documents/VPN_MixOS.conf";
      wg-off = "sudo wg-quick down /home/${username}/Documents/VPN_MixOS.conf";
      sv = "sudo nvim";
      v = "nvim";
      c = "clear";
      fr = "nh os switch --hostname ${profile}";
      fu = "nh os switch --hostname ${profile} --update";
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
      cat = "bat";
      man = "batman";
      ls = "eza --icons --group-directories-first -1";
      ll = "eza --icons -a --group-directories-first -1 --no-user --long";
      tree = "eza --icons --tree --group-directories-first";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "eastwood";
    };
  };
}
