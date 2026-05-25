#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  init-python-uv-flake.sh [target-dir] [project-name] [shell-tag] [dependencies...]

Examples:
  init-python-uv-flake.sh
  init-python-uv-flake.sh ~/projects/my-rl my-rl rl-dev numpy
  init-python-uv-flake.sh . py-rl rl-dev numpy scipy matplotlib
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

target_dir="${1:-.}"
project_name="${2:-$(basename "$PWD")}"
shell_tag="${3:-${project_name}-dev}"
shift_count=0

if [ "$#" -ge 1 ]; then shift_count=1; fi
if [ "$#" -ge 2 ]; then shift_count=2; fi
if [ "$#" -ge 3 ]; then shift_count=3; fi
shift "$shift_count"

dependencies=("$@")
if [ "${#dependencies[@]}" -eq 0 ]; then
  dependencies=("numpy")
fi

mkdir -p "$target_dir"

flake_file="$target_dir/flake.nix"
pyproject_file="$target_dir/pyproject.toml"

for file in "$flake_file" "$pyproject_file"; do
  if [ -e "$file" ]; then
    echo "Refusing to overwrite existing file: $file" >&2
    exit 1
  fi
done

cat > "$flake_file" <<EOF
{
  description = "Development shell for $project_name";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          python = pkgs.python314;
        in
        {
          default = pkgs.mkShell {
            packages = [
              python
              pkgs.uv
            ];

            env = {
              UV_PYTHON = "\${python}/bin/python";
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              export PS1="($shell_tag) \$PS1"

              if [ -d .venv ]; then
                export VIRTUAL_ENV="\$PWD/.venv"
                export PATH="\$VIRTUAL_ENV/bin:\$PATH"
              fi
            '';
          };
        });
    };
}
EOF

{
  cat <<EOF
[project]
name = "$project_name"
version = "0.1.0"
description = ""
requires-python = ">=3.14"
dependencies = [
EOF

  for dependency in "${dependencies[@]}"; do
    printf '  "%s",\n' "$dependency"
  done

  cat <<'EOF'
]
EOF
} > "$pyproject_file"

echo "Created:"
echo "  $flake_file"
echo "  $pyproject_file"
echo
echo "Next steps:"
echo "  cd $target_dir"
echo "  nix develop"
echo "  uv lock"
echo "  uv sync"
