{
  description = "Development shell for py-rl";

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
              UV_PYTHON = "${python}/bin/python";
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              export PS1="(rl-dev) $PS1"

              if [ -d .venv ]; then
                export VIRTUAL_ENV="$PWD/.venv"
                export PATH="$VIRTUAL_ENV/bin:$PATH"
              fi
            '';
          };
        });
    };
}
