{
  description = "HP-CPR companion app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forEachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      mkShells =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };

          android = pkgs.androidenv.composeAndroidPackages {
            cmdLineToolsVersion = "latest";
            platformToolsVersion = "latest";
            buildToolsVersions = [ "36.0.0" ];
            platformVersions = [
              "35"
              "36"
            ];
            includeEmulator = false;
            includeNDK = true;
            ndkVersion = "28.2.13676358";
            includeCmake = true;
            extraLicenses = [
              "android-googletv-license"
              "android-googlexr-license"
              "android-sdk-arm-dbt-license"
              "android-sdk-license"
              "android-sdk-preview-license"
              "google-gdk-license"
              "intel-android-extra-license"
              "intel-android-sysimage-license"
              "microxr-sysimage-license"
              "mips-android-sysimage-license"
            ];
          };

          androidSdk = android.androidsdk;

          commonPackages = with pkgs; [
            flutter
            git
            curl
            jq
            ripgrep
            unzip
            zip
          ];

          ciPackages = commonPackages ++ [
            pkgs.chromium
            pkgs.actionlint
            pkgs.nixfmt
          ];

          androidPackages = commonPackages ++ [
            pkgs.jdk21
            androidSdk
          ];

          defaultPackages = commonPackages ++ [
            pkgs.chromium
            pkgs.actionlint
            pkgs.gh
            pkgs.nixfmt
            pkgs.jdk21
            androidSdk
          ];

          commonHook = ''
            export PUB_CACHE="''${PUB_CACHE:-$HOME/.pub-cache}"
            export PATH="$PUB_CACHE/bin:$PATH"

            if [ -d .git ] && [ -d .githooks ]; then
              git config --local core.hooksPath .githooks
            fi
          '';

          ciEnv = ''
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"
          '';

          androidEnv = ''
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export JAVA_HOME="${pkgs.jdk21.home}"
          '';

          mkShell =
            name: packages: extraEnv:
            pkgs.mkShell {
              inherit packages;
              shellHook = ''
                ${commonHook}
                ${extraEnv}
                echo "HP-CPR ${name} development shell" >&2
                echo "Run 'flutter doctor -v' to verify the toolchain." >&2
              '';
            };
        in
        {
          default = mkShell "default" defaultPackages (ciEnv + androidEnv);
          ci = mkShell "ci" ciPackages ciEnv;
          android = mkShell "android" androidPackages androidEnv;
        };
    in
    {
      devShells = forEachSystem (system: mkShells system);

      formatter = forEachSystem (system: (import nixpkgs { inherit system; }).nixfmt);
    };
}
