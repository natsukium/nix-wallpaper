{ lib
, runCommandLocal
, imagemagick

, preset ? "official"
, width ? 3480
, height ? 2160
, logoSize ? 44.25

, backgroundColor ? null
, logoColors ? { }
, logoRotate ? "-0"
, logoGravity ? "center"
, logoOffset ? "+0+0"

  # secret option for source-code readers
, widdershins ? false
}:

let
  isNixFile = file: type: (lib.hasSuffix ".nix" file && type == "regular");
  isColor = str: builtins.isString str && (builtins.isList (builtins.match "^#[0-9a-fA-F]{6}$" str));
in

assert builtins.isInt width && width > 0;
assert builtins.isInt height && height > 0;
assert (builtins.isInt logoSize || builtins.isFloat logoSize) && logoSize >= 0;
assert builtins.isString preset;
assert lib.assertMsg
  (lib.hasAttr "${preset}.nix"
    (lib.filterAttrs isNixFile (builtins.readDir ../data/presets)))
  "unknown preset \"${preset}\"";
assert lib.assertMsg (backgroundColor == null || isColor backgroundColor)
  "backgroundColor should be a 6-digit hex code";
assert lib.assertMsg (builtins.all isColor (lib.attrValues logoColors))
  "logoColors should contain 6-digit hex codes";
assert lib.assertMsg
  (builtins.all
    (str: builtins.isList (builtins.match "^color[0-5]$" str))
    (lib.attrNames logoColors))
  "logoColors should contain keys named color[0-5]";
assert builtins.isBool widdershins;

let
  colorscheme = import ../data/presets/${preset}.nix
    // logoColors //
    lib.optionalAttrs (backgroundColor != null) { inherit backgroundColor; };
in
runCommandLocal "nix-wallpaper"
rec {
  inherit width height logoGravity logoOffset logoRotate;
  inherit (colorscheme) color0 color1 color2 color3 color4 color5 backgroundColor;
  buildInputs = [ imagemagick ];
  density = 1200;
  # 72 is the default density
  # 323 is the height of the image rendered by default
  scale = 72.0 / density * height / 323.0 * logoSize;
  flop = if widdershins then "-flop" else "";
} ''
  mkdir -p $out/share/wallpapers
  substituteAll ${../data/svg/wallpaper.svg} wallpaper.svg
  convert \
    -resize ''${scale}% \
    -density $density \
    -background $backgroundColor \
    -rotate ''${logoRotate} \
    -gravity ''${logoGravity} \
    -extent ''${width}x''${height}''${logoOffset} \
    $flop \
    wallpaper.svg $out/share/wallpapers/nixos-wallpaper.png
''
