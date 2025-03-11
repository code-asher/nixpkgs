{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchNpmDeps,
  buildGoModule,
  makeWrapper,
  moreutils,
  jq,
  git,
  rsync,
  pkg-config,
  python3,
  esbuild,
  nodejs,
  node-gyp,
  npmHooks,
  libsecret,
  xorg,
  ripgrep,
  AppKit,
  Cocoa,
  CoreServices,
  Security,
  cctools,
  xcbuild,
  quilt,
  nixosTests,
}:

let
  system = stdenv.hostPlatform.system;

  python = python3;

  esbuild' = esbuild.override {
    buildGoModule =
      args:
      buildGoModule (
        args
        // rec {
          version = "0.16.17";
          src = fetchFromGitHub {
            owner = "evanw";
            repo = "esbuild";
            rev = "v${version}";
            hash = "sha256-8L8h0FaexNsb3Mj6/ohA37nYLFogo5wXkAhGztGUUsQ=";
          };
          vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
        }
      );
  };

  # replaces esbuild's download script with a binary from nixpkgs
  patchEsbuild = path: version: ''
    mkdir -p ${path}/node_modules/esbuild/bin
    jq "del(.scripts.postinstall)" ${path}/node_modules/esbuild/package.json | sponge ${path}/node_modules/esbuild/package.json
    sed -i 's/${version}/${esbuild'.version}/g' ${path}/node_modules/esbuild/lib/main.js
    ln -s -f ${esbuild'}/bin/esbuild ${path}/node_modules/esbuild/bin/esbuild
  '';

  # Comment from @code-asher, the code-server maintainer
  # See https://github.com/NixOS/nixpkgs/pull/240001#discussion_r1244303617
  #
  # If the commit is missing it will break display languages (Japanese, Spanish,
  # etc). For some reason VS Code has a hard dependency on the commit being set
  # for that functionality.
  # The commit is also used in cache busting. Without the commit you could run
  # into issues where the browser is loading old versions of assets from the
  # cache.
  # Lastly, it can be helpful for the commit to be accurate in bug reports
  # especially when they are built outside of our CI as sometimes the version
  # numbers can be unreliable (since they are arbitrarily provided).
  #
  # To compute the commit when upgrading this derivation, do:
  # `$ git rev-parse <git-rev>` where <git-rev> is the git revision of the `src`
  # Example: `$ git rev-parse v4.16.1`
  commit = "cc3c22deee4392aac109a16cb57063c24dd5fa78";
  # TODO: There has to be a better way?  I tried to run `npm ci` in a derivation
  # and copy the npm cache into $out but kept getting "illegal path references".
  npmHashes = {
    "" = "sha256-kSnII1YCPPYv8kVv62v+4xstQzhmYev/wEmfF21ApfA=";
    "lib/vscode" = "sha256-hvj8pXgQA/Y+SoZ/+KAof1ANIxgCDmE9h0uTPqFSdpM=";
    "lib/vscode/build" = "sha256-vUm4asM3bz+16pGgciXA+go11I3+Y+IFZmvLjKa3too=";
    "lib/vscode/build/npm/gyp" = "sha256-eG2bE30drub5sQ9qvgfx2U/JueAXsQLM5bM4uqsN38w=";
    "lib/vscode/extensions" = "sha256-TGEHqNAfwXF81ftxttxTkpUpYRBKvqzjji5VV0KCbBs=";
    "lib/vscode/extensions/configuration-editing" = "sha256-/XrKa3y2bBcDY9VMn8C35VlN40IbVg+FAxtNKqdnNSM=";
    "lib/vscode/extensions/css-language-features" = "sha256-I0JmCdtPo3Kl8s6JI0Gs7CE5GrrnspSaMY6wASJ8VxU=";
    "lib/vscode/extensions/css-language-features/server" = "sha256-O5U24bT1XlkQPAW6lRO6vXEK8XqqFEa17PcWX/90Ek4=";
    "lib/vscode/extensions/debug-auto-launch" = "sha256-wSBZc6/1aTvo1ED1HR/rjVoO+tYJKoiWTjxNG6q5wR4=";
    "lib/vscode/extensions/debug-server-ready" = "sha256-Dgp/vM8nxMqcoaco+BK0IW1LyOfikd1ycqE+0XjoI68=";
    "lib/vscode/extensions/emmet" = "sha256-BNseZW9q4psBfLjrxo0m/SAfKwq0k9P/a/qKw+wxqXc=";
    "lib/vscode/extensions/extension-editing" = "sha256-OOGZRShuPfohBk6HohKA3bRf5GuG9BZObm2Y4OCqNhY=";
    "lib/vscode/extensions/git" = "sha256-TveKM97CunSOuBAxrxDgkdYkcvjpIxW2/0+fETilht4=";
    "lib/vscode/extensions/git-base" = "sha256-coGnGFgMlR0gs0DrhtrJ/W5sJ7NocY7f3kwwewPHZb4=";
    "lib/vscode/extensions/github" = "sha256-GM4dSdlRZCmSKMd6Q0WSkCuOHWS5ZeWB/kY/lu2cILU=";
    "lib/vscode/extensions/github-authentication" = "sha256-7icHdk1K4cIlF/kQkX8BnAkRTarXebv7VpUBOMaW1t4=";
    "lib/vscode/extensions/grunt" = "sha256-cytMJnJD+uLGf7+1/D3YMrB8PHF7B4cC9IPfCgBsGww=";
    "lib/vscode/extensions/gulp" = "sha256-vi8NJNDJjfoRLjsDT891NE7sXBJoIq/KoZ/4zKMqagk=";
    "lib/vscode/extensions/html-language-features" = "sha256-Wa9Wfwu8785vE7BpOH+UoH3y9P/e/Zwa63OBkDsalPc=";
    "lib/vscode/extensions/html-language-features/server" = "sha256-xTH9+EeubVtioq6dFWiEbHDUZrJbXBPjkquB8vYt5B4=";
    "lib/vscode/extensions/ipynb" = "sha256-bdV4o46P2UFY+liMPtpwAPD2nQMpoOk7Sz8oQZWK24g=";
    "lib/vscode/extensions/jake" = "sha256-vTkw/QkYkuoarD+ietUGKpX1ypCTYDOcwyFuMeqhvOc=";
    "lib/vscode/extensions/json-language-features" = "sha256-92s7i4LuuxdbxzuBHf9c03YJOiqyv/ro4mjeECq2wIQ=";
    "lib/vscode/extensions/json-language-features/server" = "sha256-jMx6LsGCb/vb4UOLMzqf2Lvp0rLY02fkd0ApVC6qDw0=";
    "lib/vscode/extensions/markdown-language-features" = "sha256-Abe+7DI7iW+CsCO6QcGugMILzUObvvQ8dHBSkEM5FI0=";
    "lib/vscode/extensions/markdown-math" = "sha256-f7trHpw4OrofHZ79MdnfNJd1ZHlmtIHd9iCI+cNac0k=";
    "lib/vscode/extensions/media-preview" = "sha256-oHSfamtY1/2+f2T4qShpw0dl9Hv3af+ygj4bTJ0wUMA=";
    "lib/vscode/extensions/merge-conflict" = "sha256-ynUV74+7iTTxRN0JQAUXiecp2HtJ4X53HI7nSJRMNHs=";
    "lib/vscode/extensions/microsoft-authentication" = "sha256-Q3yd0HtRnrZa34lmVEdCIYPejAz4UMLDlWQzgHpG51I=";
    "lib/vscode/extensions/notebook-renderers" = "sha256-vHmdXBCA3XLwrOqY+TkKHY/hfQvc+9n0YA5xeYvprhQ=";
    "lib/vscode/extensions/npm" = "sha256-Y/yrvfafNhEi4AB78ydlrb5BTJa3JFOKPtSZexBgQMo=";
    "lib/vscode/extensions/php-language-features" = "sha256-B/Dpwq0fGdsPEXfIgAyLxz2GsvV5hsFEFkZRl5siuOk=";
    "lib/vscode/extensions/references-view" = "sha256-UI0FSW9+OTWUXIBi/rL2iMDxlam0WtwDXWwvaOWt+ag=";
    "lib/vscode/extensions/simple-browser" = "sha256-DTHZIddI9TsHgypEAP6EoC5kHAenabv10xVv3nsd66A=";
    "lib/vscode/extensions/tunnel-forwarding" = "sha256-LngWoia6J+8YCVc1eSfHhH+/SBm80OG0Y2pi7PcqzmQ=";
    "lib/vscode/extensions/typescript-language-features" = "sha256-2psyMVHZ3u7WjtuAP+nx7+cskQMc59rgi9sCu6TDKbc=";
    "lib/vscode/extensions/vscode-api-tests" = "sha256-9X6A+heX9KMoLiM/c3OI0vkRMpUAFJX7lNO2f1G+hrE=";
    "lib/vscode/extensions/vscode-colorize-perf-tests" = "sha256-jCdW/BIl2lSW/12CgPN9iF5aJjYT0qtQnYZICKXoT6k=";
    "lib/vscode/extensions/vscode-colorize-tests" = "sha256-prp6rSI9Nrr0uWwNaU4TeFNG8MZ1iNH6OxFGx8eeC0g=";
    "lib/vscode/extensions/vscode-test-resolver" = "sha256-lr4Xw9YvRwRAGjVhkPJqvGkIWF6nWeGBNQwy6z2ahRc=";
    "lib/vscode/remote" = "sha256-rEBpZdNWmeArjOGPEI5tB3KWebs45Yf5laQDFenaDos=";
    "lib/vscode/remote/web" = "sha256-o3KgvAbtWWMi0C+W6zdM92qJ2ZQISo1uAC0PXH/YXMY=";
  };
  npmDeps = src: builtins.mapAttrs (path: hash:
    fetchNpmDeps {
      src = "${src}/${path}";
      hash = hash;
      # The emmet extension has a dependency that points to a git repo that has
      # no lock file, so add the flag to bypass that error.  Seems like this
      # will almost certainly break...
      forceGitDeps = baseNameOf(path) == "emmet";
    }
  ) npmHashes;
  # - Not sure why installing the emmet extension dependencies errors about the
  #   cache not being writable while everything else is fine.  Something about
  #   the git dependency it uses, probably.
  # - The emmet extension has a dependency that points to a git repo that has no
  #   lock file, so add the flag to bypass that error.
  npmConfigHooks = deps: builtins.mapAttrs (path: dep: ''
    makeCacheWritable=${builtins.toString (baseNameOf(path) == "emmet")} \
    forceGitDeps=${builtins.toString (baseNameOf(path) == "emmet")} \
      npmRoot=${path} npmDeps=${dep} npmConfigHook
  '') deps;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "code-server";
  version = "4.98.0";

  src = fetchFromGitHub {
    owner = "coder";
    repo = "code-server";
    rev = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-oeG8fap7HTr9oyIpOYgb7XDiPCp/LgadAQi9ZAlMKK4=";
  };

  nativeBuildInputs = [
    nodejs
    python
    pkg-config
    makeWrapper
    git
    rsync
    jq
    moreutils
    quilt
  ];

  buildInputs =
    [
      xorg.libX11
      xorg.libxkbfile
    ]
    ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
      libsecret
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      AppKit
      Cocoa
      CoreServices
      Security
      cctools
      xcbuild
    ];

  npmPackFlags = [ "--ignore-scripts" ];
  npmRebuildFlags = [ "--ignore-scripts" ];

  patches = [
    # Remove all git calls from the VS Code build script except `git rev-parse
    # HEAD` which is replaced in postPatch with the commit.
    ./build-vscode-nogit.patch
    # Patch out remote download of nodejs from build script.
    ./remove-node-download.patch
  ];

  postPatch = ''
    export HOME=$PWD

    patchShebangs ./ci

    # inject git commit
    substituteInPlace ./ci/build/build-vscode.sh \
      --replace-fail '$(git rev-parse HEAD)' "${commit}"
    substituteInPlace ./ci/build/build-release.sh \
      --replace-fail '$(git rev-parse HEAD)' "${commit}"
  '';

  configurePhase = ''
    runHook preConfigure

    # Skip unnecessary downloads.
    export ELECTRON_SKIP_BINARY_DOWNLOAD=1
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    export SKIP_SUBMODULE_DEPS=1

    export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"

    # Run configure for each set of npm dependencies.
    (
      local postPatchHooks=() # written to by npmConfigHook
      source ${npmHooks.npmConfigHook}/nix-support/setup-hook
      ${lib.concatStrings
        (builtins.attrValues (npmConfigHooks (npmDeps finalAttrs.src)))}
    )

    runHook postConfigure
  '';

  buildPhase =
    ''
      runHook preBuild

      # Apply patches.
      quilt push -a

      # Remove all "built-in" extensions (distinct from the actually built-in
      # extensions found in lib/vscode/extensions) found in the product.json;
      # these are downloaded from the VS Code marketplace.
      jq --slurp '.[0] * .[1]' "./lib/vscode/product.json" <(
        cat << EOF
      {
        "builtInExtensions": []
      }
      EOF
      ) | sponge ./lib/vscode/product.json

      # Disable automatic updates.
      sed -i '/update.mode/,/\}/{s/default:.*/default: "none",/g}' \
        lib/vscode/src/vs/platform/update/common/update.config.contribution.ts

      # Use esbuild from nixpkgs.
      ${patchEsbuild "./lib/vscode/build" "0.12.6"}
      ${patchEsbuild "./lib/vscode/extensions" "0.11.23"}

      # Use ripgrep from nixpkgs.
      find -name ripgrep -type d \
        -execdir mkdir -p {}/bin \; \
        -execdir ln -s ${ripgrep}/bin/rg {}/bin/rg \;

      # Build code-server, VS Code, and the built-in extensions.
      npm run build
      VERSION=${finalAttrs.version} npm run build:vscode

      # Inject version into package.json.
      jq --slurp '.[0] * .[1]' ./package.json <(
        cat << EOF
      {
        "version": "${finalAttrs.version}"
      }
      EOF
      ) | sponge ./package.json

      # Create release, keeping all dependencies.
      KEEP_MODULES=1 npm run release

      # Prune development dependencies.  We only need to do this for the root as
      # the VS Code build process already does this for VS Code.
      npm prune --omit=dev --prefix release

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/code-server $out/bin

    # copy release to libexec path
    cp -R -T release "$out/libexec/code-server"

    # create wrapper
    makeWrapper "${nodejs}/bin/node" "$out/bin/code-server" \
      --add-flags "$out/libexec/code-server/out/node/entry.js"

    runHook postInstall
  '';

  passthru = {
    tests = {
      inherit (nixosTests) code-server;
    };
    # vscode-with-extensions compatibility
    executableName = "code-server";
    longName = "Visual Studio Code Server";
  };

  meta = {
    changelog = "https://github.com/coder/code-server/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    description = "Run VS Code on a remote server";
    longDescription = ''
      code-server is VS Code running on a remote server, accessible through the
      browser.
    '';
    homepage = "https://github.com/coder/code-server";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      offline
      henkery
      code-asher
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
    ];
    mainProgram = "code-server";
  };
})
