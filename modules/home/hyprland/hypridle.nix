{ ... }:

{
  services = {
    hypridle = {
      enable = true;
      settings = {
        general = { 
          before_sleep_cmd = "qylock-lock";
          after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
          ignore_dbus_inhibit = false;
          lock_cmd = "qylock-lock";
          };
        listener = [
          {
            timeout = 1200;
            on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
            on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
          }
        ];
      };
    };
  };
}
