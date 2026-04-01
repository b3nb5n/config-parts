{ lib, config, ... }: {
  argsLib = let
    inherit (lib.types) enum either;
    inherit (lib.attrsets) mapAttrs filterAttrs;
  in rec {
    excluded = "CONFIG_PARTS_EXCLUDED_ARGUMENT";
    excludedOr = either (enum [ excluded ]);

    filterExcluded = filterAttrs (_name: value: value != excluded);
    isEscaped = lib.strings.hasPrefix "_";
    filterEscaped = filterAttrs (name: _value: !(isEscaped name));
    filter = args: filterEscaped (filterExcluded args);

    mkOption = args:
      let
        typeArgs = { type = excludedOr args.type; };
        _defaultArgs = { default = excluded; };
        defaultArgs = if args ? "default" then { } else _defaultArgs;
      in lib.mkOption (args // typeArgs // defaultArgs);

    mkOptions = mapAttrs (_name: mkOption);

    mkGlobalOption = args:
      lib.mkOption (args // {
        type = excludedOr args.type;
        default = excluded;
      });

    mkGlobalOptions = mapAttrs (_name: mkGlobalOption);

    filterExcluded = filterAttrs (_name: value: value != excluded);
    isEscaped = lib.strings.hasPrefix "_";
    filterEscaped = filterAttrs (name: _value: !(isEscaped name));
    filter = args: filterEscaped (filterExcluded args);
  };

  hmLib = {
    parseOutputName = name:
      let
        split = lib.strings.splitString "@" name;
        components = if (builtins.length split) <= 2 then split else [ name ];
        componentAttr = idx: name:
          if idx < (builtins.length components) then {
            "${name}" = builtins.elemAt components idx;
          } else
            { };

        user = componentAttr 0 "outputUser";
        host = componentAttr 1 "outputHost";
      in user // host;

    defaultHostConfig = hostName:
      let
        allHostConfigs = [ config.flake.nixosConfigurations ];

        getConfig = hostConfigAttrs:
          if hostConfigAttrs ? "${hostName}" then
            hostConfigAttrs.${hostName}
          else
            null;

        _hostConfigs = builtins.map getConfig allHostConfigs;
        hostConfigs = builtins.filter (config: config != null) _hostConfigs;

        hasHostName = builtins.isString hostName;
        hasDefaultConfig = (builtins.length hostConfigs) == 1;
      in if hasHostName && hasDefaultConfig then
        builtins.elemAt hostConfigs 0
      else
        null;
  };
}
