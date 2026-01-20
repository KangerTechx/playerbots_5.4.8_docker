#!/bin/sh
set -e

# --- Default variables (can be overridden in .env) ---
PROJECT_NAME="${PROJECT_NAME:-Pandaria}"

SQL_INSTALL_DIR="${SQL_INSTALL_DIR:-/app/sql/install}"
SQL_TMP_DIR="$SQL_INSTALL_DIR/tmp"
SQL_UPDATES_DIR="${SQL_UPDATES_DIR:-/src/playerbots_5.4.8/sql/updates}"
SQL_BASE_DIR="${SQL_BASE_DIR:-/src/playerbots_5.4.8/sql/base}"

# These filenames must exist in the extracted zips
AUTH_SQL="${AUTH_SQL:-auth_20_01_2026.sql}"
CHARACTER_SQL="${CHARACTER_SQL:-characters_20_01_2026.sql}"
WORLD_SQL="${WORLD_SQL:-world_20_01_2026.sql}"
PLAYERBOTS_SQL="${PLAYERBOTS_SQL:-playerbots_20_01_2026.sql}"

# Output bundle files (always generated with these names)
AUTH_BUNDLE="$SQL_INSTALL_DIR/auth_base.sql"
CHAR_BUNDLE="$SQL_INSTALL_DIR/characters_base.sql"
WORLD_BUNDLE="$SQL_INSTALL_DIR/world_base.sql"
PLAYERBOTS_BUNDLE="$SQL_INSTALL_DIR/playerbots_base.sql"
WORLD_UPDATE="$SQL_INSTALL_DIR/world_update.sql"

AUTH_PATCHES="$SQL_INSTALL_DIR/auth_patches_update.sql"
CHAR_PATCHES="$SQL_INSTALL_DIR/characters_patches_update.sql"
WORLD_PATCHES="$SQL_INSTALL_DIR/world_patches_update.sql"
PLAYERBOTS_PATCHES="$SQL_INSTALL_DIR/playerbots_patches_update.sql"

# --- Prepare directories ---
mkdir -p "$SQL_INSTALL_DIR" "$SQL_TMP_DIR"
rm -f "$SQL_INSTALL_DIR"/*.sql


# --- Télécharger le zip world si pas déjà présent ---
if [ ! -f "$SQL_BASE_DIR/world_20_01_2026.zip" ]; then
    echo "Downloading world database..."
    curl -L "$WORLD_DB_URL" -o "$SQL_BASE_DIR/world_20_01_2026.zip"
else
    echo "world_20_01_2026.zip already exists in $SQL_BASE_DIR, skipping download."
fi

echo "=== Building bundled SQL files for $PROJECT_NAME ==="

# --- Extract base SQL from zips ---
echo "Unzipping base databases..."
unzip -o "$SQL_BASE_DIR/auth_*.zip" -d "$SQL_TMP_DIR"
unzip -o "$SQL_BASE_DIR/characters_*.zip" -d "$SQL_TMP_DIR"
unzip -o "$SQL_BASE_DIR/world_*.zip" -d "$SQL_TMP_DIR"
unzip -o "$SQL_BASE_DIR/playerbots_*.zip" -d "$SQL_TMP_DIR"

# Move/rename base SQL to consistent names
mv -f "$SQL_TMP_DIR/$AUTH_SQL" "$AUTH_BUNDLE"
mv -f "$SQL_TMP_DIR/$CHARACTER_SQL" "$CHAR_BUNDLE"
mv -f "$SQL_TMP_DIR/$WORLD_SQL" "$WORLD_BUNDLE"
mv -f "$SQL_TMP_DIR/$PLAYERBOTS_SQL" "$PLAYERBOTS_BUNDLE"

# --- Find and prepare latest world update ---
LATEST_WORLD_ZIP=$(find "$SQL_INSTALL_DIR" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | head -n1)

if [ -z "$LATEST_WORLD_ZIP" ]; then
    echo "Downloading latest world dump..."
    [ -z "$WORLD_DB_URL" ] && { echo "Error: WORLD_DB_URL is not set."; exit 1; }
    LATEST_WORLD_ZIP="$SQL_INSTALL_DIR/latest_world.zip"
    wget --progress=bar:force:noscroll "$WORLD_DB_URL" -O "$LATEST_WORLD_ZIP"
fi

echo "Extracting latest world update..."
unzip -o "$LATEST_WORLD_ZIP" -d "$SQL_TMP_DIR"

LATEST_WORLD_SQL=$(find "$SQL_TMP_DIR" -maxdepth 1 -type f -name '*.sql' | head -n1)
if [ -z "$LATEST_WORLD_SQL" ]; then
    echo "Error: No SQL file found inside $LATEST_WORLD_ZIP."
    exit 1
fi
mv -f "$LATEST_WORLD_SQL" "$WORLD_UPDATE"

# --- Merge incremental patches ---
merge_patches() {
    local src_dir="$1"
    local target="$2"

    if [ ! -d "$src_dir" ]; then
        echo "No patches in $src_dir, skipping."
        return
    fi

    echo "Merging patches from $src_dir into $target..."

    find "$src_dir" -type f -name '*.sql' -print0 \
      | sort -z \
      | xargs -0 -r cat > "$target"

    [ -s "$target" ] || echo "-- No patches merged" > "$target"
}

merge_patches "$SQL_UPDATES_DIR/auth" "$AUTH_PATCHES"
merge_patches "$SQL_UPDATES_DIR/characters" "$CHAR_PATCHES"
merge_patches "$SQL_UPDATES_DIR/world" "$WORLD_PATCHES"
merge_patches "$SQL_UPDATES_DIR/playerbots" "$PLAYERBOTS_PATCHES"

# --- Normalize DB names in all SQL files ---
echo "Normalizing database names..."
for file in "$SQL_INSTALL_DIR"/*.sql; do
    [ -f "$file" ] || continue
    echo "Patching $file..."
    sed -i -E "s/(CREATE DATABASE.*|USE) *\`auth\`/\1 \`$AUTH_DB\`/Ig" "$file"
    sed -i -E "s/(CREATE DATABASE.*|USE) *\`characters\`/\1 \`$CHARACTER_DB\`/Ig" "$file"
    sed -i -E "s/(CREATE DATABASE.*|USE) *\`world\`/\1 \`$WORLD_DB\`/Ig" "$file"
    sed -i -E "s/(CREATE DATABASE.*|USE) *\`playerbots\`/\1 \`$PLAYERBOTS_DB\`/Ig" "$file"
done

# --- Cleanup ---
rm -rf "$SQL_TMP_DIR"

echo "=== All bundled SQL files for $PROJECT_NAME are ready in $SQL_INSTALL_DIR ==="
ls -1 "$SQL_INSTALL_DIR"/*.sql || echo "(No files generated)"
