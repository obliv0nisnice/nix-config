{ pkgs, ... }:
{
  home.packages = with pkgs; [ pyprland ];

  home.file.".config/pypr/config.toml".text = ''
    [pyprland]
    plugins = ["scratchpads"]

    [scratchpads.term]
    animation = "fromTop"
    command = "kitty --class kitty-dropterm"
    class = "kitty-dropterm"
    size = "75% 60%"
    max_size = "1920px 100%"
    margin = 50
    # pinned = true   # inzwischen Standard, nur falls du es explizit machen willst

    [scratchpads.volume]
    animation = "fromRight"
    command = "pavucontrol"
    class = "org.pulseaudio.pavucontrol"
    lazy = true
    size = "40% 90%"
    unfocus = "hide"

    [scratchpads.thunar]
    animation = "fromBottom"
    command = "thunar"
    class = "thunar"
    size = "75% 60%"
    lazy = true
  '';
}
