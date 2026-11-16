{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl
    foot
    fuzzel
    grim
    pulseaudio # pactl for the volume keys, including with PipeWire.
    slurp
    swaylock
    swaynotificationcenter
    waybar
    wl-clipboard
  ];

  fonts.packages = [ pkgs.inter ];
  services.pipewire.enable = lib.mkDefault (!config.services.pulseaudio.enable);
  services.pipewire.pulse.enable = lib.mkDefault (
    !config.services.pulseaudio.enable && (config.services.pipewire.audio.enable or true)
  );

  environment.etc."driftwm/acer.toml".source = ./desktop/driftwm.toml;
  environment.etc."waybar/acer.json".source = ./desktop/waybar.json;
  environment.etc."waybar/acer.css".source = ./desktop/waybar.css;
}
