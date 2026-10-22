#!/usr/bin/env bash
# Installs and configures the Obsidian plugins behind the "New post" button.
#
#   ./scripts/install-obsidian-plugins.sh
#
# Everything this script writes lives in .obsidian/ (gitignored, local-only).
# The parts worth versioning are here: this script, templates/hugo-post.md and
# docs/obsidian-setup.md.
set -euo pipefail

VAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS="$VAULT/.obsidian/plugins"
mkdir -p "$PLUGINS"

install_plugin() { # $1 = owner/repo, $2 = plugin id
  local repo="$1" id="$2" dir="$PLUGINS/$2" tag
  mkdir -p "$dir"
  if [ -z "${FORCE:-}" ] && [ -s "$dir/main.js" ] && [ -s "$dir/manifest.json" ]; then
    echo "   $id already installed ($(python3 -c "import json;print(json.load(open('$dir/manifest.json'))['version'])" 2>/dev/null))"
    return 0
  fi
  tag="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$tag" ] || { echo "!! could not resolve latest release for $repo"; return 1; }
  for f in main.js manifest.json styles.css; do
    curl -fsSL --retry 3 --max-time 120 -o "$dir/$f" \
      "https://github.com/$repo/releases/download/$tag/$f" 2>/dev/null \
      || rm -f "$dir/$f"
  done
  echo "   $id @ $tag"
}

echo "Installing Obsidian plugins into $PLUGINS"
install_plugin SilentVoid13/Templater templater-obsidian
install_plugin mnaoumov/obsidian-custom-attachment-location obsidian-custom-attachment-location
install_plugin mnaoumov/obsidian-advanced-rename-and-delete-handler advanced-rename-and-delete-handler
install_plugin jsmorabito/obsidian-commander cmdr

# --- Templater: where the new-post template lives -------------------------
cat > "$PLUGINS/templater-obsidian/data.json" <<'JSON'
{
  "templates_folder": "templates",
  "trigger_on_file_creation": false,
  "auto_jump_to_cursor": true,
  "enable_system_commands": false,
  "user_scripts_folder": "templates/scripts"
}
JSON

# --- Custom Attachment Location: images land in static/assets/<post>/ -----
# {{noteFileName}} is the note's base name, which is already <date>-<slug>,
# so a drop writes static/assets/<date>-<slug>/<image>.png and the link it
# inserts is the /assets/... path Hugo serves.
cat > "$PLUGINS/obsidian-custom-attachment-location/data.json" <<'JSON'
{
  "shouldFollowObsidianAttachmentLocation": false,
  "attachmentFolderPath": "static/assets/{{noteFileName}}",
  "generatedAttachmentFileName": "{{originalAttachmentFileName}}",
  "markdownUrlFormat": "/assets/{{noteFileName}}/{{generatedAttachmentFileName}}.{{attachmentFileExtension}}",
  "attachmentRenameMode": "Only pasted images"
}
JSON

# --- Advanced Rename and Delete Handler: required by the plugin above -----
# Defaults do nothing; they only gate loading. Left empty on purpose.
printf '{}\n' > "$PLUGINS/advanced-rename-and-delete-handler/data.json"

# --- Commander: the actual "New post" ribbon button -----------------------
# leftRibbon entries are { id: <obsidian command id>, icon, name, mode }.
cat > "$PLUGINS/cmdr/data.json" <<'JSON'
{
  "leftRibbon": [
    {
      "id": "templater-obsidian:create-new-note-from-template",
      "icon": "file-plus",
      "name": "New post",
      "mode": "any"
    }
  ]
}
JSON

# --- Enable everything ----------------------------------------------------
python3 - "$VAULT" <<'PY'
import json, pathlib, sys
vault = pathlib.Path(sys.argv[1])
path = vault / ".obsidian" / "community-plugins.json"
enabled = json.loads(path.read_text()) if path.exists() else []
for pid in [
    "templater-obsidian",
    "obsidian-custom-attachment-location",
    "advanced-rename-and-delete-handler",
    "cmdr",
]:
    if pid not in enabled and (vault / ".obsidian" / "plugins" / pid / "manifest.json").exists():
        enabled.append(pid)
path.write_text(json.dumps(enabled, indent=2) + "\n")
print("Enabled:", ", ".join(enabled))
PY

cat <<'EOF'

Done. Open Obsidian once and turn off Restricted mode
(Settings -> Community plugins) so the plugins load.

The ribbon now has a "New post" button: it asks for a title and tags, then
creates content/posts/<date>-<slug>.md plus static/assets/<date>-<slug>/.
Dropping an image into a post saves it into that folder and links it as
/assets/<date>-<slug>/<image>.png, which is what Hugo serves.
EOF
