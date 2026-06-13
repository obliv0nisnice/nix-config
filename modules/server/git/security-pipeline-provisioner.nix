{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machineProfiles.server.gitea.workflowProvisioner;
  giteaCfg = config.machineProfiles.server.gitea;

  workflowFile = ./security-pipeline.yml;
  workflowPath = ".gitea/workflows/security.yml";

  script = pkgs.writeShellApplication {
    name = "gitea-security-workflow-provisioner";
    runtimeInputs = with pkgs; [ curl jq coreutils ];
    text = ''
      set -euo pipefail

      GITEA_URL="${cfg.giteaUrl}"
      TOKEN_FILE="${cfg.tokenFile}"
      WORKFLOW_SRC="${workflowFile}"

      if [ ! -r "$TOKEN_FILE" ]; then
        echo "Token file missing: $TOKEN_FILE — provisioner is idle until secrets are configured." >&2
        exit 0
      fi
      TOKEN=$(tr -d '\n' < "$TOKEN_FILE")
      WORKFLOW_B64=$(base64 -w0 "$WORKFLOW_SRC")
      EXPECTED_SHA=$(sha256sum "$WORKFLOW_SRC" | cut -d' ' -f1)

      page=1
      while :; do
        repos=$(curl -fsSL \
          -H "Authorization: token $TOKEN" \
          "$GITEA_URL/api/v1/repos/search?limit=50&page=$page")
        count=$(echo "$repos" | jq '.data | length')
        if [ "$count" -eq 0 ]; then
          break
        fi

        echo "$repos" | jq -r '.data[] | "\(.full_name)\t\(.archived)\t\(.empty)\t\(.default_branch)"' \
          | while IFS=$'\t' read -r full_name archived empty default_branch; do

            if [ "$archived" = "true" ] || [ "$empty" = "true" ]; then
              echo "skip ($full_name): archived=$archived empty=$empty"
              continue
            fi

            current=$(curl -s -w "\n%{http_code}" \
              -H "Authorization: token $TOKEN" \
              "$GITEA_URL/api/v1/repos/$full_name/contents/${workflowPath}?ref=$default_branch")
            status=$(echo "$current" | tail -n1)
            body=$(echo "$current" | sed '$d')

            if [ "$status" = "200" ]; then
              current_sha=$(echo "$body" | jq -r '.content' | base64 -d | sha256sum | cut -d' ' -f1)
              if [ "$current_sha" = "$EXPECTED_SHA" ]; then
                echo "ok ($full_name): workflow up to date"
                continue
              fi

              file_sha=$(echo "$body" | jq -r '.sha')
              echo "update ($full_name): updating ${workflowPath}"
              payload=$(jq -nc \
                --arg msg "ci: update security pipeline workflow" \
                --arg branch "$default_branch" \
                --arg content "$WORKFLOW_B64" \
                --arg sha "$file_sha" \
                '{message:$msg, branch:$branch, content:$content, sha:$sha}')

              http_status=$(curl -s -o /tmp/dt-prov-resp.json -w "%{http_code}" \
                -X PUT \
                -H "Authorization: token $TOKEN" \
                -H "Content-Type: application/json" \
                "$GITEA_URL/api/v1/repos/$full_name/contents/${workflowPath}" \
                -d "$payload")

              if [ "$http_status" != "200" ]; then
                echo "error ($full_name): update failed (HTTP $http_status)"
                cat /tmp/dt-prov-resp.json >&2 || true
                echo >&2
              else
                echo "ok ($full_name): workflow updated"
              fi
              continue
            fi

            if [ "$status" != "404" ]; then
              echo "warn ($full_name): unexpected status $status"
              continue
            fi

            echo "provision ($full_name): adding ${workflowPath}"
            payload=$(jq -nc \
              --arg msg "ci: add security pipeline workflow" \
              --arg branch "$default_branch" \
              --arg content "$WORKFLOW_B64" \
              '{message:$msg, branch:$branch, content:$content}')

            http_status=$(curl -s -o /tmp/dt-prov-resp.json -w "%{http_code}" \
              -X POST \
              -H "Authorization: token $TOKEN" \
              -H "Content-Type: application/json" \
              "$GITEA_URL/api/v1/repos/$full_name/contents/${workflowPath}" \
              -d "$payload")

            if [ "$http_status" != "201" ] && [ "$http_status" != "200" ]; then
              echo "error ($full_name): provisioning failed (HTTP $http_status)"
              cat /tmp/dt-prov-resp.json >&2 || true
              echo >&2
            else
              echo "ok ($full_name): workflow committed"
            fi
          done

        page=$((page + 1))
      done
    '';
  };
in
{
  options.machineProfiles.server.gitea.workflowProvisioner = {
    enable = lib.mkEnableOption "auto-provision security pipeline workflow into every Gitea repo" // {
      default = giteaCfg.enable;
    };

    giteaUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://gitea.nestlerlabs.at";
      description = "Base URL of the Gitea instance the provisioner talks to.";
    };

    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/gitea/provisioner-token";
      description = ''
        Path to a file containing a Gitea Personal Access Token with
        `repo` scope. Default expects the sops-managed secret defined in
        modules/server/secrets.nix.
      '';
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd OnCalendar expression for the provisioner run.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.gitea-security-workflow-provisioner = {
      description = "Provision the security pipeline workflow into all Gitea repos";
      after = [ "gitea.service" "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${script}/bin/gitea-security-workflow-provisioner";
      };
    };

    systemd.timers.gitea-security-workflow-provisioner = {
      description = "Periodic provisioning of Gitea security workflow";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10m";
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    };
  };
}
