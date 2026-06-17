{ pkgs, lib, ... }:
let
  # Shows a random Pokémon sprite next to fastfetch, rendered as a real image via
  # kitty-direct (wie das nixos.png-Logo). Größe passt sich dem Terminal an.
  # Funktioniert nur in kitty.
  #
  # >>> Bildstil wählen: <<<
  #   "artwork" – gestochen scharfe, gezeichnete Render-Artworks (~475px)
  #   "pixel"   – die klassischen 96px-Battle-Sprites (Pixel-Art)
  style = "artwork";

  ids = {
    victini = 494;
    mimikyu = 778;
    celebi = 251;
    furret = 162;
    mewtwo = 150;
    pikachu = 25;
    eevee = 133;
    espeon = 196;
    umbreon = 197;
    vaporeon = 134;
    jolteon = 135;
    flareon = 136;
    gengar = 94;
    snorlax = 143;
    lucario = 448;
    gardevoir = 282;
    lapras = 131;
    dragonite = 149;
    charizard = 6;
    cyndaquil = 155;
    totodile = 158;
    chikorita = 152;
    rowlet = 722;
    mew = 151;
  };

  # Pfad-Suffix unter .../sprites/pokemon/ je Stil und Variante.
  subPath = {
    pixel = {
      normal = "";
      shiny = "shiny/";
    };
    artwork = {
      normal = "other/official-artwork/";
      shiny = "other/official-artwork/shiny/";
    };
  };

  hashes = {
    pixel = {
      normal = {
        victini = "sha256-7svrNOnPCkPvyoxtzWbmwUC6cWBujBA5QAhyC2prztA=";
        mimikyu = "sha256-YgeDXkj4b97e09kJMrIlYsiJN1sT5TLGsKQOJwpqCmo=";
        celebi = "sha256-AE/OZxiUYJvbuS3xI+nDqoe0p/Dj4O793eJk4ddIggI=";
        furret = "sha256-xfWnHhBGiX7uInc275kp2GbdkRXMwgno+j/fmQKwu+E=";
        mewtwo = "sha256-McWuuxNKNxGGSpIJHLG1w1FY5OkMpciK/d9W8M9LwSk=";
        pikachu = "sha256-gNMOsbnyoF60ohbVMDTioLsW8mGexD0oHzbWAeWBnCw=";
        eevee = "sha256-Vq1Ow2mq23EhiwgOame4XuqXs81j+dMJfWPZtLdIPfk=";
        espeon = "sha256-RFmGoDp/0ity0dZ1MX4+xVCuLUskwTlMPvO7rE3zEFY=";
        umbreon = "sha256-ct9KskIitHDi0UXAx0e3BKSrykBC1znmRaDjfvfur1w=";
        vaporeon = "sha256-cJdVuGdtyr8JzK2KmLKvkYhp+KCSsn7irH0lyv2/7ok=";
        jolteon = "sha256-F6khW9gnbfjN/DhwnpVlUbaZGIc4v2KMq4mlW9OE+F0=";
        flareon = "sha256-gNZPsuetSS5o1Kej5I70MCdSRsbkjaSzZ47r/ZA7jEQ=";
        gengar = "sha256-AK1KWJ+fwaiPd9zVEkd+LhJOxAMLAdjnhnAPrRTTjq0=";
        snorlax = "sha256-EW9nZQ2eIUXjB/4VO6ao+6O90CYG/7A2TAXnG1oNuks=";
        lucario = "sha256-//Xb/nchOrSb3ntwYq7j2FGi7LXscnWW0y1b/wTW3fI=";
        gardevoir = "sha256-cC+9XZt8LIf08uSydvPU+PWPIfkkt2fY+snaELleLOo=";
        lapras = "sha256-aST+HH3vyW3uUK1iY1YFNEI0EKzNtxwDjom9VemuigQ=";
        dragonite = "sha256-CSFnU66WoB0URKdWhUi7/Psi/l3nYFFR4eAbqsfN2jg=";
        charizard = "sha256-UzWLfovpEBS9GChYYr1WwFSbXSOvF13rWfDm9jOch48=";
        cyndaquil = "sha256-WtmFsRZcojZHS76Soyxwf6E5QYoSxXvTl7KnUF5GHsQ=";
        totodile = "sha256-hhpXigGTgNyCeZ1MOdKD2u7PRu2PRBsCrbF9YXkD5M0=";
        chikorita = "sha256-24LIqIe00oKOPoUvaJz/6+Kxps/Bcy+lci/uvbvqecg=";
        rowlet = "sha256-wfDbz2mLPoZhYakOoQbg2+57FHh1uz44dL1Gd/gr7pc=";
        mew = "sha256-377q/WMkAwRNqPGpgUJWEtP96A+wv89swl3n0VCwJbo=";
      };
      shiny = {
        victini = "sha256-juytpF3wm3V8dETep7LLNnC/vq14+STJ934cikroJhs=";
        mimikyu = "sha256-qVZnarVRRWozVFydEVJfciz07krhvQpedL3dtiZCtHY=";
        celebi = "sha256-u4qJrh+aeVwkb7iv6fsMQUntc98QOiIbnBZrefz4ueQ=";
        furret = "sha256-8oTsdIFmpyNwr8RwkVorWYTCnaPjAD3vkjt1PJfkfOk=";
        mewtwo = "sha256-h5D1MdYVfA4VndSAm6H6nKYblP9fNiMsjSiLHr+2Zco=";
        pikachu = "sha256-E7SbIvME8CE7zJaA/2QXt0vgIgx8yNi7K43z6mw4wNs=";
        eevee = "sha256-t4q9JdnVUUvtgiIdFOaxi30DbEhlE2MmB0+/dAsSfzI=";
        espeon = "sha256-2qQ3G9CvQtK+k76KtEt6aTP3KTSrjrQwvZ+QkSkGSZI=";
        umbreon = "sha256-4eob9Uxn8iMxPbGIyI/9z8yRdwQ1thgF5e9FzzNY2yA=";
        vaporeon = "sha256-jj3/hW6gce5hrJQXJ5cv8rQhDqMDLCl6YkvhQ89Fqug=";
        jolteon = "sha256-XiZdg6s3a798xO4k3jFOEPeMGL4pWHeqvuz1TisK9iE=";
        flareon = "sha256-xyWtPg1ihGgCfCrGNkjoZYUVJLPyRLgF10VG3g2jUPc=";
        gengar = "sha256-uqcs6gBEohfNjnwhd+YWRcegjdi0dKSincPEqplCNbk=";
        snorlax = "sha256-3JWr03eNxWPpeiJhJk8ew9uGfCVSYyLW8pMeMwAE2VY=";
        lucario = "sha256-Fr32go2OMJOeoyuj7oP3e04pXkNOYbc7P8rn7cxhb5A=";
        gardevoir = "sha256-6iMX7rw6s1lidQkRISW83nVQIA7zK207Tee4Ixp5U1s=";
        lapras = "sha256-6MabiKrksrve0zm2c5fpkJLXm+0BJQhOkySbrrEeFOU=";
        dragonite = "sha256-2If0HOtMzTTgDt9dDC3btaNaiqjME54+owgGSP/u3T8=";
        charizard = "sha256-LURuwG12DoehRU0l5xVEOJh0I3PH5Lye2V4ksfjvmF4=";
        cyndaquil = "sha256-0ajv85jwNFYi8KjDZPgTu8r5PW3myzVOHJRKSt96tiI=";
        totodile = "sha256-UwBKFX5GfpHPX71ScxEqhaPhm2pWv1VMUF/6pokoB6c=";
        chikorita = "sha256-oJE3nxUbMvomKG7E2K14pdRNKXxPJ88jg4BmGdi2A9M=";
        rowlet = "sha256-wHeHHwmniZuNe82px2/gd5d1vXm2c6YP3uyKjscUPuU=";
        mew = "sha256-/jLVMCXduEc5T9Zt2MWAwSMj4fxm6EMRY/29S5jSsac=";
      };
    };
    artwork = {
      normal = {
        victini = "sha256-Z8vQ2Wn3dNN8NAsJZfYiKS9wb7tyHY229fOT9fLLnmQ=";
        mimikyu = "sha256-PzaLP7Ba8XG2rAzok+4GWupuYIvkXgQIevGQL8Q6twg=";
        celebi = "sha256-MThP1FwmY8Hm7ZTe64sWx+Lgpa+0646pX+8XWrNDCL4=";
        furret = "sha256-mZ7G8qkC4S7NslwsIajt4uzzHNXaPyMzPGZB545QJgQ=";
        mewtwo = "sha256-2ZreubRSMHPKIYpvRy6ltgKwR8zYr43qb6euBR+ANmo=";
        pikachu = "sha256-dZzq/bS41jffz+Zzz2crw8RyNUo7Ln4INdnNys2NGV0=";
        eevee = "sha256-M+qZPTR47pIAYrC/J3kqBFs6L3XZQb24yzkS71Cx+0Q=";
        espeon = "sha256-0OdLAq3D3wf5vwJjA7EGjFgYP4cDriykK417WOmgaW8=";
        umbreon = "sha256-jX8Y97MjJp3/hEgPHuiHOl1Ho+s/1LKsHSu/DPRabd0=";
        vaporeon = "sha256-P0qG7y7AZMmN2PsgcEbHICwWaeX7f6wF/BrOo2TSdw8=";
        jolteon = "sha256-v1JcILiZ4IOY2T0ENtLlkkYwaNhdqHYEJKw0DH+Pjtg=";
        flareon = "sha256-oR0/AhuvkX+RBiZtX+xbYyaihQsTDkVg4zP6n0gcQew=";
        gengar = "sha256-tlSbgFN2dvz0pYnIhTs4zOQvQrX3B7vi5jeXZmF1zwY=";
        snorlax = "sha256-Gv0y5fYFOlCGDWfF18w7xsqaF0Y0CX/mWIBSOgoTpVo=";
        lucario = "sha256-jFBk8dSjfItVTXrYPXeXCwLWh1dQ+TTHgkk8g/iUMSc=";
        gardevoir = "sha256-rECz6H3pVwbK6WMYArl1iC+YMMFSglPTZ8+n/T8pV70=";
        lapras = "sha256-/9mISd7gomW7EJ2XmNv9GLNTRqHCHKAaoNq2CnLe+8Y=";
        dragonite = "sha256-S9dUnKoV6sQ6gZe6U+hDqV8rVscbESGCnqdnZPvyb5w=";
        charizard = "sha256-ttW47p+wXcb1MpSyyuZg3sdwuSdizbGdFry9Z54bpDo=";
        cyndaquil = "sha256-+jYzx1f5t+HfqJg3f7IObbuRR0Alt1P65SZFsiNW210=";
        totodile = "sha256-QroSM1iMf3AjRnLzaWxUTk+hUkBxTru9LkjP+DO6H5o=";
        chikorita = "sha256-tIMTkfSPoe7AiNrQmjcJA1AjaFOjpPIpcjFdHwh9dYo=";
        rowlet = "sha256-PwG/RbM/lFWlVtedfpyO0RuJeddw/qa/iwp22lPHzyM=";
        mew = "sha256-mZGu5RgReLYEuZrsY2UzsMWlKjIc4kbdO5wzJDo0KmQ=";
      };
      shiny = {
        victini = "sha256-Q3hm8/T9Sp5HU2+GIBVj6KBQvC0K11aE640kNb396xo=";
        mimikyu = "sha256-dmApOq3E1DIjpqmc3IbHeZZUcduM+COwn+pgwFWELO8=";
        celebi = "sha256-cy/ojxlqkFQm9MSENxsDBSGjE2rUKB1fKwi+yMfJIqM=";
        furret = "sha256-EMvGgdqapdMsNYmUdkYZuo/cp4KsT4ZMU81P/WLM06Q=";
        mewtwo = "sha256-ha16xsiX9cfH+0b6q7dA2hJHmed/2Z72P50S7zuCd18=";
        pikachu = "sha256-neV4vuZmXRpFiEaGsdNV9nrt1DUi8x4HO/1uD1joSgM=";
        eevee = "sha256-nw5uQ2kSAwrPh70hvCmnDf5WBOkKD+2UyOQbiYtzjxo=";
        espeon = "sha256-T7p4+ojqwO5dlZXZTxNYLN1nf6IbClTi2gzf8+s5j9M=";
        umbreon = "sha256-0FFvRDNc/8FcpxSkuFih+YfMG41M+84gdocSFyYJZoY=";
        vaporeon = "sha256-8MC3ZYOQFEGt78b6J45dUuC44gyrFjU3vwQAdWt8AnI=";
        jolteon = "sha256-NNhLYSxPKl+tDhJ6ItSRpT/s9eLxWncL8Jp8w1DTIGU=";
        flareon = "sha256-Gv+tfNsvc36idblxZkci/FmB7Ev+s1LAb8Y8+xPlhf0=";
        gengar = "sha256-9+jfUnQ/dU413/34oNO6pw+Lxp5R8LUZYZd0n8cYNB0=";
        snorlax = "sha256-gK15MsSm3vBfp/64IDlxJOwh0LS6gL0p19ZbUeGUQ98=";
        lucario = "sha256-t83aDWHd3RnwrQ4awdO/2gq0u47CWcJexoBfXbkpe1M=";
        gardevoir = "sha256-K/GXpB4EcQaYZ7V0qLIq9sdLv1LLwcUv0/Fc46xbBu0=";
        lapras = "sha256-3UCFPZYGNaT8Z0tKkJR0cFYaB0nhZcVLjxkwao6IIXw=";
        dragonite = "sha256-l5DUYmJRbhhZo2K2rRKzpMFJqRC9uGeAsWVcLenJdYU=";
        charizard = "sha256-eXw+wEDzYb9Xt89q6eL/E2fw1RLSm4tqhptG/n0w/9Q=";
        cyndaquil = "sha256-uNeKDSPBUPCa9GXCS6Frx9Cl2as05CUMXdPgIrgKIxI=";
        totodile = "sha256-eqPMXYcRTtTbgzr4PuKTyyDTPaefHg4o/HGteu2KcBU=";
        chikorita = "sha256-17V3YAY5UU7fKq2byhUrjJ1GtUzbuYc915KgcKJ1gcs=";
        rowlet = "sha256-eQKnZmzBLMk//u/aPHzHvxEflMWXg7MYl7iSbsvjt7A=";
        mew = "sha256-G2BplFLJHLACHO2pJsNtPt00PZPUowkjpggkXx19IDc=";
      };
    };
  };

  base = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon";
  # Holt für den gewählten Stil sowohl Normal- als auch Shiny-Sprites in
  # $out/normal/<name>.png bzw. $out/shiny/<name>.png.
  fetchVariant =
    variant:
    lib.concatStrings (
      lib.mapAttrsToList (
        name: id:
        "cp ${
          pkgs.fetchurl {
            url = "${base}/${subPath.${style}.${variant}}${toString id}.png";
            sha256 = hashes.${style}.${variant}.${name};
          }
        } $out/${variant}/${name}.png\n"
      ) ids
    );
  sprites = pkgs.runCommand "pokesprites-${style}" { } (
    "mkdir -p $out/normal $out/shiny\n" + fetchVariant "normal" + fetchVariant "shiny"
  );
  pokemonList = lib.concatStringsSep " " (lib.attrNames ids);

  pokefetch = pkgs.writeShellScriptBin "pokefetch" ''
    POKEMON_LIST=(${pokemonList})
    FETCHER="${pkgs.fastfetch}/bin/fastfetch"

    # Sprite passt sich der Terminalgröße an. Grenzen nach Geschmack anpassen.
    MIN_HEIGHT=4
    MAX_HEIGHT=11
    # Chance auf ein Shiny: 1 zu N (kleiner = häufiger). 0 = nie.
    SHINY_CHANCE=15

    # fastfetch-Texthöhe (für vertikale Zentrierung des Sprites)
    FETCHER_HEIGHT=$($FETCHER --logo none | wc -l)

    # Terminalgröße (Fallback, falls kein TTY verfügbar ist)
    cols=$(tput cols 2>/dev/null || echo 80)
    lines=$(tput lines 2>/dev/null || echo 24)

    # Höhe ~ ein Viertel der Terminalhöhe, geklammert auf [MIN_HEIGHT, MAX_HEIGHT].
    LOGO_HEIGHT=$((lines / 4))
    (( LOGO_HEIGHT < MIN_HEIGHT )) && LOGO_HEIGHT=$MIN_HEIGHT
    (( LOGO_HEIGHT > MAX_HEIGHT )) && LOGO_HEIGHT=$MAX_HEIGHT

    # Bild ist quadratisch -> Breite ~ 2x Höhe (Zellen sind ~1:2). Nicht breiter
    # als die halbe Terminalbreite, sonst quetscht es den Text.
    LOGO_WIDTH=$((LOGO_HEIGHT * 2))
    maxw=$((cols / 2))
    (( LOGO_WIDTH > maxw )) && { LOGO_WIDTH=$maxw; LOGO_HEIGHT=$((LOGO_WIDTH / 2)); }

    # vertikal zentrieren
    pad_top=$((($FETCHER_HEIGHT - $LOGO_HEIGHT) / 2))
    (( pad_top < 0 )) && pad_top=0

    name=''${POKEMON_LIST[RANDOM % ''${#POKEMON_LIST[@]}]}

    # Seltener Shiny-Encounter ✨
    variant=normal
    if (( SHINY_CHANCE > 0 )) && (( RANDOM % SHINY_CHANCE == 0 )); then
      variant=shiny
    fi

    $FETCHER \
      --logo ${sprites}/$variant/$name.png \
      --logo-type kitty-direct \
      --logo-width $LOGO_WIDTH \
      --logo-height $LOGO_HEIGHT \
      --logo-padding-top $pad_top \
      --logo-padding-left 2
  '';
in
{
  home.packages = [ pokefetch ];
}
