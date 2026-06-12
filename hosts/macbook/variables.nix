{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "oblivion";#"obliv0nisnice";
  gitEmail = "anrufen_nahm0p@icloud.com";

  # Hyprland Settings
  extraMonitorSettings = "
      monitor=DP-2,2560x1440@165,0x0,1
      monitor=HDMI-A-1,1920x1080@60,0x-1080,1
      monitor=DP-1,2560x1440@60,-1440x-1000, 1, transform,3
  ";
  
  workspaceSettings = [
        "name:1, monitor:DP-2"
        "name:2, monitor:DP-1"
        "name:3, monitor:HDMI-A-1"
      ];


  guiActivation = true;


  # Waybar Settings
  clock24h = true;

  # Program Options
  browser = "floorp"; # Set Default Browser
  terminal = "kitty"; # Set Default System Terminal
  keyboardLayout = "de";
  consoleKeyMap = "de";
  
}
