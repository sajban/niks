{
  description = "Niks; reusable nix from Uniks";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = selfInputs@{ self, nixpkgs, flake-utils }:
    let
      inherit (nixpkgs) lib;
      inherit (flake-utils.lib) eachDefaultSystem;
      inherit (builtins) functionArgs intersectAttrs;

      mkLinuxPkgs = import ./mkLinuxPkgs.nix;

      mkLambdaWithArgs = { lambda, args }:
        let
          requestedArgs = functionArgs lambda;
          returnedArgs = intersectAttrs requestedArgs args;
        in
        lambda returnedArgs;

      mkPackage =
        { lambda
        , extraInputs ? { }
        , pkgs ? { }
        , nixpkgs ? { }
        , overlays ? [ ]
        }@args:
        let
          nixpkgs =
            if (args.nixpkgs != { }) then args.nixpkgs else selfInputs.nixpkgs;

          hasOverlays = overlays != [ ];

          mkOutputs = system:
            let
              overlayedPkgs = mkLinuxPkgs {
                inherit lib system overlays;
                src = nixpkgs;
              };

              pkgs =
                if (args.pkgs != { }) then args.pkgs
                else
                  if hasOverlays then overlayedPkgs
                  else nixpkgs.legacyPackages.${system};

            in
            mkLambdaWithArgs {
              inherit lambda;
              args = pkgs
                // extraInputs
                // { inherit lib system; };
            };

          perSystemOutputs = eachDefaultSystem mkOutputs;

        in
        perSystemOutputs;

      mkElispPackage =
        { lambda
        , extraInputs ? { }
        , nixpkgs ? { }
        , overlays ? [ ]
        }@args:
        let
          nixpkgs =
            if (args.nixpkgs != { }) then args.nixpkgs else selfInputs.nixpkgs;

          emacsFlavors = [ "stable" "git" "unstable" "gcc" "pgtk" "pgtkGcc" ];

          mkPackageFlavor = flavor:
            let emacs = if flavor == "stable" then { } else { };
            in
            { };

          packageFlavors = lib.genAttrs emacsFlavors mkPackageFlavor;
        in
        { };

    in
    { inherit mkLinuxPkgs mkLambdaWithArgs mkPackage; };
}
