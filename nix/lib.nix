{ lib, ... }: {
  argsLib = let
    inherit (lib.types) enum listOf either deferredModule;
    inherit (lib.attrsets) mapAttrs filterAttrs;
  in rec {
    excluded = "CONFIG_PARTS_EXCLUDED_ARGUMENT";
    excludedOr = either (enum [ excluded ]);

    isExcluded = value: value == excluded;
    isEscaped = lib.strings.hasPrefix "_";

    mkGlobalOption = _name: args:
      lib.mkOption (args // {
        type = excludedOr args.type;
        default = excluded;
      });

    globalOptions = {
      _modules = lib.mkOption {
        type = listOf deferredModule;
        default = [ ];
      };
    };

    mkGlobalOptions = optionArgs:
      globalOptions // (mapAttrs mkGlobalOption optionArgs);

    isGlobal = name: (builtins.elem name (builtins.attrNames globalOptions));
    filterGlobal =
      filterAttrs (name: value: !(isGlobal name) && !(isExcluded value));

    mkOption = name: args:
      let
        escaped = isEscaped name;
        mkType = if escaped then (ty: ty) else excludedOr;
        typeArgs = { type = mkType args.type; };
        _defaultArgs = { default = excluded; };
        defaultArgs = if args ? "default" then { } else _defaultArgs;
      in lib.mkOption (args // typeArgs // defaultArgs);

    mkOptions = mapAttrs mkOption;

    filter =
      filterAttrs (name: value: !(isEscaped name) && !(isExcluded value));
  };

  hmLib = {
    parseOutputName = outputName:
      let
        components = lib.strings.splitString "@" outputName;
        component = idx:
          if idx < (builtins.length components) then
            builtins.elemAt components idx
          else
            null;
      in {
        inherit outputName;
        outputUser = component 0;
        outputHost = component 1;
      };
  };
}
