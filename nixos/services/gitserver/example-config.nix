# Example Git server configuration
# This file shows how to enable and configure the Git SSH server
# Copy the relevant parts to your configuration.nix or create a separate module

{ config, pkgs, ... }:

{
  services.gitserver = {
    # Enable the Git SSH server
    enable = true;

    # User and group for Git operations (optional, defaults shown)
    user = "git";
    group = "git";

    # Directory where repositories will be stored (optional, default shown)
    repoDir = "/var/lib/git";

    # SSH public keys that can access the repositories
    # Add your SSH public keys here
    authorizedKeys = [
      # Example: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKey user@hostname"
      # Example: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... user@hostname"
    ];

    # Repositories to initialize as bare repositories
    # These will be created automatically at /var/lib/git/
    repositories = [
      "myproject.git"
      "dotfiles.git"
      "notes.git"
    ];
  };
}
