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

      mkDevShell =
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
            platformVersions = [ "36" ];
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
        in
        pkgs.mkShell {
          packages = [
            pkgs.flutter
            pkgs.jdk21
            androidSdk
            pkgs.chromium
            pkgs.curl
            pkgs.git
            pkgs.gh
            pkgs.jq
            pkgs.ripgrep
            pkgs.unzip
            pkgs.zip
          ];

          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          JAVA_HOME = "${pkgs.jdk21.home}";
          CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";

          shellHook = ''
            export PUB_CACHE="''${PUB_CACHE:-$HOME/.pub-cache}"
            export PATH="$PUB_CACHE/bin:$PATH"

            echo "HP-CPR development shell" >&2
            echo "Run 'flutter doctor -v' to verify the toolchain." >&2
          '';
        };
    in
    {
      devShells = forEachSystem (system: {
        default = mkDevShell system;
      });

      formatter = forEachSystem (system: (import nixpkgs { inherit system; }).nixfmt);
    };
}
