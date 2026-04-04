{ lib, ... }: rec {
  excluded = "CONFIG_PARTS_EXCLUDED_ARGUMENT";
  excludedOr = lib.types.either (lib.types.enum [ excluded ]);

  isExcluded = value: value == excluded;
  isEscaped = lib.strings.hasPrefix "_";

  filter = lib.attrsets.filterAttrs
    (name: value: !(isEscaped name || isExcluded value));
}
