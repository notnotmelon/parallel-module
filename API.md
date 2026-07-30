# Parallel Module API

### Prototypes

Parallel Module works by creating hidden copies of each valid recipe, where each copy is for a given parallel value and the probabilities of its results altered according to the parallel formula for that parallel value. At runtime, crafting machines' recipes are seamlessly swapped based their parallel value.

In order for Parallel Module to work properly for a given recipe or entity prototype, the prototype must be defined and in a valid state before Parallel Module's `data-final-fixes.lua` runs. For a prototype to be in a valid state means that, were the engine to load that prototype as-is (without any further downstream changes) it would load correctly. Because Parallel Module copies prototypes, it can copy invalid prototypes, which will prevent the game from starting.

Any changes made to a prototype after Parallel Module's `data-final-fixes.lua` runs can cause Parallel Module to behave incorrectly:

* Changes to a recipe prototype will not be reflected in its parallel versions.
* Increasing an entity's module slots (including due to quality) can cause missing parallel recipes.
* Changing Parallel Module's `mod_data` parameters will lead to undefined behavior.

### Runtime

At runtime, Parallel Module swaps between recipes depending on crafting machines' parallel values; this is mostly straightforward for compatibility.

Currently, the supported entities are:
`rocket-silo`
`assembling-machine`

## Parallel Module Parameters 

Parallel Module has several parameters it uses in its calculations. These can be modified by editing the fields of the `parallel_module_mod_data` mod data object, i.e. `data.raw['mod-data'].parallel_module_mod_data.data`:

* `max_total_parallel` (`double`): Default `64` (`+64000%` = `64x`). Determines the maximum possible parallel value an entity can have (analagous to the 300% productivity maximum for most recipes). Must be an integer.

#### See [`mod-data.lua`](prototypes/mod-data.lua) for more details.

## Recipes

Parallel Module adds several prototype fields for specifying how parallel modules interact with recipes.

#### New `RecipeCategoryPrototype` Fields:

* `parallel_blacklist` (`boolean`): Default `false`. If set to `true`, recipes with this category are not considered valid for parallel unless they either have another (non-blacklisted) category, or are marked with `parallel_whitelist = true`.

#### New `RecipePrototype` Fields:

* `allow_parallel` (`boolean`): Default `true`. If set to `false`, parallel modules will be disabled for this recipe. Overrides any other considerations.

#### New `AssemblingMachinePrototype` Fields:

* `effect_receiver.base_effect.parallel` (`double`): Default `0.0`. The base parallel value that will applied to all (valid) recipes made in entities of this prototype. This is analagous to the base productivity of e.g. the foundry. Recipes that do not accept parallel modules can still be made in an entity with a non-zero base parallel, and will be unaffected.

## Other

Module category compatibility should be done through [Module category defaults](https://mods.factorio.com/mod/module-category-defaults).
