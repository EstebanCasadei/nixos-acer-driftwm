{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    waybar
    swaynotificationcenter
  ];

  environment.etc."driftwm/acer.toml".source = ./desktop/driftwm.toml;
  environment.etc."waybar/acer.json".source = ./desktop/waybar.json;
}
