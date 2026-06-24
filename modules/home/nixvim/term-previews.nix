{ pkgs, ... }:
let
  # Local plugins that render documents as images in a Kitty split.
  typst-preview-term = pkgs.vimUtils.buildVimPlugin {
    pname = "typst-preview-term";
    version = "0.1.0";
    src = ./typst-preview-term;
  };
  md-preview-term = pkgs.vimUtils.buildVimPlugin {
    pname = "md-preview-term";
    version = "0.1.0";
    src = ./md-preview-term;
  };
  # in-buffer fit-to-width markdown table renderer
  md-table-fit = pkgs.vimUtils.buildVimPlugin {
    pname = "md-table-fit";
    version = "0.1.0";
    src = ./md-table-fit;
  };
in
{
  # Both registered here: default.nix merges modules with recursiveUpdate, which
  # replaces lists rather than concatenating them, so extraPlugins/extraPackages
  # must be defined in a single place.
  extraPlugins = [
    typst-preview-term
    md-preview-term
    md-table-fit
  ];
  extraConfigLua = ''
    require("typst-preview-term").setup({})
    require("md-preview-term").setup({})
    require("md-table-fit").setup({})
  '';
  # runtime tools for the markdown (GitHub-style) preview pipeline
  extraPackages = [
    pkgs.cmark-gfm
    pkgs.python3Packages.weasyprint
    pkgs.poppler-utils
    pkgs.imagemagick
  ];
}
