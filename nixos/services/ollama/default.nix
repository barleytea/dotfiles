# Ollama service configuration
{ pkgs, ... }:

{
  services.ollama.enable = true;

  # Install the Ollama CLI so it is available for local use
  environment.systemPackages = with pkgs; [
    ollama
  ];
}

