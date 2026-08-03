# Parallel Module API

### Prototypes

Parallel Module works by creating hidden copies of each valid recipe, where each copy is for a given parallel value and the probabilities of its results altered according to the parallel formula for that parallel value. At runtime, crafting machines' recipes are seamlessly swapped based their parallel value.

In order for Parallel Module to work properly for a given recipe or entity prototype, the prototype must be defined and in a valid state before Parallel Module's `data-final-fixes.lua` runs. For a prototype to be in a valid state means that, were the engine to load that prototype as-is (without any further downstream changes) it would load correctly. Because Parallel Module copies prototypes, it can copy invalid prototypes, which will prevent the game from starting.

Any changes made to a prototype after Parallel Module's `data-final-fixes.lua` runs can cause Parallel Module to behave incorrectly:

* Changes to a recipe prototype will not be reflected in its parallel versions.
* Increasing an entity's module slots (including due to quality) can cause missing parallel recipes.
* Changing Parallel Module's `mod_data` parameters will lead to undefined behavior.

### Runtime

At runtime, Parallel Module swaps between recipes depending on crafting machines' parallel values.

Currently, the supported entities are:
`rocket-silo`
`assembling-machine`
`furnace`

For furnaces to function, this mod automatically converts all `furnace` prototypes into `assembling-machine` if the `parallel-module-allow-in-furnaces` setting is enabled.

#### New `RecipeCategoryPrototype` Fields:

* `parallel_blacklist` (`boolean`): Default `false`. If set to `true`, recipes with this category are not considered valid for parallel unless they either have another (non-blacklisted) category, or are marked with `parallel_whitelist = true`.

#### New `RecipePrototype` Fields:

* `allow_parallel` (`boolean`): Default `true`. If set to `false`, parallel modules will be disabled for this recipe. Overrides any other considerations.

#### New `CraftingMachinePrototype` Fields:

* `"allow_parallel"` (`boolean`): Default: Enabled if `allowed_effects` equals `{"speed", "productivity", "consumption", "pollution", "quality"}`. Determines if this machine can accept parallel modules. Overriden if this machine has base parallel.

#### New `EffectReceiver` Fields:

* `effect_receiver.base_effect.parallel` (`double`): Default `0.0`. The base parallel value that will applied to all (valid) recipes made in entities of this prototype. This is analagous to the base productivity of e.g. the foundry. Recipes that do not accept parallel modules can still be made in an entity with a non-zero base parallel, and will be unaffected.

#### New `ModulePrototype` Fields:

* `parallel_quality_multiplier` (`double`): Default `1.0 if the module parallel effect is > 0, otherwise 0.0.`. 0.0 means that no parallel scaling is applied (common for penalties). 1.0 means that the full scaling of the parallel prototype applies.

* `effect.parallel` (`double`): Default `0.0`. Defines how many parallels this module provides.

#### New `QualityPrototype` Fields:

* `module_parallel_multiplier` (`double`): Default: Value of `level`. Must be >= 0.01.
