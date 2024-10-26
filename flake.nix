{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-24.05";

    # ocaml acts up on unstable as of 2024-10-26
    # nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { 
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystemTypes = fn: nixpkgs.lib.genAttrs supportedSystems fn;
    in
    {
      devShells = forAllSystemTypes (system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        default = pkgs.mkShell {
          inputsFrom = with self.devShells.${system}; [
            building
          ];
        };
        building = pkgs.mkShell {
          packages =
            [
	      pkgs.haxe
	      pkgs.neko
              (pkgs.writeScriptBin "build" ''
                export DYLD_LIBRARY_PATH="$(which neko)/../../lib"
	        lime test cpp 
              '')
              (pkgs.writeScriptBin "setup" ''
	        mkdir ~/haxelib
		haxelib setup ~/haxelib

		# lime needs to be >= 8.2.0 for apple silicon. There are
		# other hacks here to facilitate the same build environment.
		# This is all a bit different than what is in setup.sh
		#{{{

		sudo ln -s ${pkgs.neko}/lib/* /usr/local/lib
                haxelib install lime 8.2.0
                haxelib git swf https://github.com/openfl/swf
                haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp

                haxelib run lime setup

                lime rebuild swf
                lime rebuild mac

		#}}}

		haxelib install openfl 9.3.3
		haxelib install flixel 5.6.1
		haxelib install flixel-addons 3.2.2
		haxelib install flixel-tools 1.5.1
		haxelib install hscript-iris 1.1.0
		haxelib install tjson 1.4.0
		haxelib install hxdiscord_rpc 1.2.4
		haxelib install hxvlc 1.9.2
		haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
		haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
		haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90
		haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666
		haxelib install format
		haxelib install hxp
              '')
              (pkgs.writeScriptBin "update-flake" ''
                nix flake update
              '')
            ];
        };
      });
    };
}
