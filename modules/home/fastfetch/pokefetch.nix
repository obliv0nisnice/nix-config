{ pkgs, ... }:
let
  # Shows a random Pokémon sprite next to fastfetch.
  # https://github.com/Discomanfulanito/pokefetch
  pokefetch = pkgs.writeShellScriptBin "pokefetch" ''
    # Sprites are drawn from here
    POKEMON_LIST=(
      victini
      "mimikyu -s"
      celebi
      furret
      "mewtwo --mega-y"
    )
    # Change with your fetcher
    FETCHER="${pkgs.fastfetch}/bin/fastfetch --logo none"

    FETCHER_HEIGHT=$($FETCHER | wc -l)

    # Extra settings
    EXTRA_PADDING_H=2
    EXTRA_PADDING_W=0

    # Room for the sprite
    WIDTH=38

    # Gets a sprite via pokeget
    sprite=$(${pkgs.pokeget-rs}/bin/pokeget ''${POKEMON_LIST[RANDOM % ''${#POKEMON_LIST[@]}]} --hide-name)

    # Gets sprite's height
    height=$(echo "$sprite" | wc -l)

    # Pad for vertical centering
    pad_top=$((($FETCHER_HEIGHT - $height) / 2))
    pad_top=$((pad_top + EXTRA_PADDING_H))

    # Just for safety
    (( pad_top < 0 )) && pad_top=0

    # Gets sprite's printed width (strip ANSI color codes first)
    sprite_width=$(
      printf '%s\n' "$sprite" \
      | sed 's/\x1b\[[0-9;]*m//g' \
      | awk '{ if (length > max) max = length } END { print max }'
    )

    # Calculate the lateral padding
    pad_Left=$((($WIDTH - sprite_width) / 2))
    pad_Right=$((($WIDTH - sprite_width + 1) / 2))

    pad_Left=$((pad_Left + EXTRA_PADDING_W))
    pad_Right=$((pad_Right + EXTRA_PADDING_W))

    # Just for safety
    (( pad_Left < 0 )) && pad_Left=0
    (( pad_Right < 0 )) && pad_Right=0

    echo "$sprite" | $FETCHER --file-raw - --logo-padding-top $pad_top --logo-padding-left $pad_Left --logo-padding-right $pad_Right
  '';
in {
  home.packages = [ pokefetch ];
}
