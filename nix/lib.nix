{ lib, config, ... }: {
  options = rec {
    mkOptionArgs = args:
      let
        empty = args.type.emptyValue;
        defaultArgs = if !(args ? "default") && (empty ? "value") then {
          default = empty.value;
        } else
          { };
      in args // defaultArgs;

    mkOptions = optionArgs:
      lib.attrsets.mapAttrs (_name: args: lib.mkOption (mkOptionArgs args))
      optionArgs;

    mkNullableArgs = args:
      args // {
        default = null;
        type = if (args.type.emptyValue.value or false) != null then
          lib.types.nullOr args.type
        else
          args.type;
      };

    mkNullableOptions = optionArgs:
      lib.attrsets.mapAttrs (_name: args: lib.mkOption (mkNullableArgs args))
      optionArgs;
  };

  config = rec {
    filterNull = lib.attrsets.filterAttrs (_name: value: value != null);

    isEscaped = lib.strings.hasPrefix "_";
    filterEscaped = lib.attrsets.filterAttrs (name: _value: !(isEscaped name));

    filter = args: filterEscaped (filterNull args);

    mkGlobalModule = args: { config = filterNull args; };
  };

  homeManager = rec {
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

    mkHostPkgsModule = hostName: {
      config.pkgs = let
        hostConfig = defaultHostConfig hostName;
        hasPkgs = (hostConfig != null) && (hostConfig ? "pkgs");
      in lib.mkIf hasPkgs (lib.mkDefault hostConfig.pkgs);
    };
  };
}
