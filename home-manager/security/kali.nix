# Kali Linux / Security Tools configuration for Home Manager
# This module manages penetration testing and security assessment tools

{ config, pkgs, lib, ... }:

with lib;

{
  options.security.kali = {
    enable = mkEnableOption "Kali Linux security tools";

    includeNetwork = mkEnableOption "Network scanning and analysis tools" // { default = true; };
    includeWeb = mkEnableOption "Web application security tools" // { default = true; };
    includePassword = mkEnableOption "Password testing and cracking tools" // { default = true; };
    includeExploitation = mkEnableOption "Exploitation frameworks and tools" // { default = true; };
    includeReverse = mkEnableOption "Reverse engineering tools" // { default = true; };
    includeForensics = mkEnableOption "Forensics and incident response tools" // { default = true; };
    includeWireless = mkEnableOption "Wireless security tools" // { default = true; };
  };

  config = mkIf config.security.kali.enable {
    home.packages = with pkgs;
      let
        # Network scanning and reconnaissance
        networkTools = mkIf config.security.kali.includeNetwork [
          nmap
          masscan
          zmap
          arp-scan
          traceroute
          bind
          netcat-gnu
          socat
        ];

        # Web application security
        webTools = mkIf config.security.kali.includeWeb [
          burpsuite
          zaproxy
          nikto
          sqlmap
          wpscan
          hydra
          medusa
        ];

        # Password testing and cracking
        passwordTools = mkIf config.security.kali.includePassword [
          hashcat
          john
          hydra
          medusa
          crunch
          cewl
        ];

        # Exploitation frameworks
        exploitTools = mkIf config.security.kali.includeExploitation [
          metasploit
          searchsploit
        ];

        # Reverse engineering and binary analysis
        reverseTools = mkIf config.security.kali.includeReverse [
          ghidra
          radare2
          gdb
          lldb
          binutils
          binwalk
          patchelf
          nm-nm
        ];

        # Forensics and incident response
        forensicsTools = mkIf config.security.kali.includeForensics [
          volatility
          sleuthkit
          autopsy
          wireshark
        ];

        # Wireless security
        wirelessTools = mkIf config.security.kali.includeWireless [
          aircrack-ng
          wifite2
          hostapd
          wpa_supplicant
          rfkill
        ];

        # Common utilities for security testing
        commonTools = [
          # Network analysis
          tcpdump
          tshark
          ngrep

          # SSL/TLS tools
          openssl
          mkcert

          # Cryptography
          gpg
          age

          # Encoding/decoding
          base64
          xxd
          hexdump

          # File analysis
          file
          exiftool
          strings

          # System information
          lsof
          netstat
          ss
          ps_mem

          # Text processing
          ripgrep
          fd
          jq

          # Utilities
          perl
          python3
          ruby
        ];
      in
        networkTools ++ webTools ++ passwordTools ++ exploitTools ++
        reverseTools ++ forensicsTools ++ wirelessTools ++ commonTools;

    # Environment variables for security tools
    home.sessionVariables = {
      # Ensure Metasploit database is accessible
      MSF_DATABASE_CONFIG = "${config.xdg.configHome}/metasploit/database.yml";

      # Kali-specific environment hint
      KALI_ENABLED = "1";
    };

    # Create necessary directories
    home.file = {
      "${config.xdg.configHome}/metasploit".source = builtins.toPath "${config.home.homeDirectory}/.config/metasploit";
    };
  };
}
