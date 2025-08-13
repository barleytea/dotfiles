{...}: {
  programs.nixvim = {
    colorschemes.dracula = {
      enable = true;
      settings = {
        transparent_bg = true;
        colors = {
          bg = "NONE";
        };
        overrides = {
          Normal = { bg = "NONE"; };
          NormalFloat = { bg = "NONE"; };
          SignColumn = { bg = "NONE"; };
          TelescopeNormal = { bg = "NONE"; };
          NvimTreeNormal = { bg = "NONE"; };
        };
      };
    };
  };
}