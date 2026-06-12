# Secrets (sops-nix)

Solange `secrets/secrets.yaml` nicht existiert, läuft das System mit Hardcoded-Defaults
weiter (`modules/server/secrets.nix` aktiviert sich nur, wenn die Datei vorhanden ist).

## Einmaliges Setup pro Server

1. Auf dem Zielhost (z.B. `homedepot`) den ed25519-Host-Key in einen age-Pubkey
   umwandeln:

   ```bash
   nix run nixpkgs#ssh-to-age -- < /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Den Pubkey in `.sops.yaml` unter `creation_rules.key_groups.age` eintragen.

3. Auf dem Admin-Rechner ein eigenes age-Key-Paar anlegen (Reihenfolge: erst Datei
   prüfen, dann erzeugen):

   ```bash
   mkdir -p ~/.config/sops/age
   nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt
   grep '^# public key:' ~/.config/sops/age/keys.txt
   ```

4. Auch diesen Admin-Pubkey in `.sops.yaml` eintragen.

5. Aus `secrets.yaml.example` die echte Datei erstellen und verschlüsseln:

   ```bash
   cp secrets/secrets.yaml.example secrets/secrets.yaml
   nix run nixpkgs#sops -- -e -i secrets/secrets.yaml
   ```

6. `secrets/secrets.yaml` committen (verschlüsselter Inhalt).

## Neue Secrets hinzufügen

`nix run nixpkgs#sops -- secrets/secrets.yaml` öffnet den Editor mit der entschlüsselten
Datei. Format: YAML mit String-Werten (für env-Files auf Container-Seite das ganze
`KEY=VALUE`-Set als Multiline-String).

## Was die Module erwarten

| Secret Key                  | Konsument                          | Format                         |
|-----------------------------|------------------------------------|--------------------------------|
| `sonarqube/env`             | docker `sonarqube` + `sonarqube-db`| env-File (`KEY=VALUE`-Zeilen)  |
| `dependency-track/env`      | docker `dtrack-*`                  | env-File                       |
| `homesuite/env`             | systemd homesuite-backend          | env-File (`ConnectionStrings__DefaultConnection=...`) |
| `gitea/db-password`         | gitea services.gitea.database      | nur das Passwort, eine Zeile   |
| `gitea/runner-token`        | gitea-actions-runner               | nur der Token                  |
| `gitea/provisioner-token`   | Workflow-Auto-Provisioner          | Gitea PAT mit Repo-Scope       |
