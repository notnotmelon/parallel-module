[![foundrygg.com](https://img.shields.io/badge/foundrygg-4a1402?style=for-the-badge&logo=vercel&logoColor=white)](https://foundrygg.com) [![](https://img.shields.io/badge/Discord-Community-blue?style=for-the-badge)](https://discord.gg/jv8CZtCh5Y) [![](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fparallel-module&style=for-the-badge)](https://mods.factorio.com/mod/parallel-module) [![](https://img.shields.io/github/issues/notnotmelon/parallel-module?label=Bug%20Reports&style=for-the-badge)](https://github.com/notnotmelon/parallel-module/issues) [![](https://img.shields.io/github/issues-pr/notnotmelon/parallel-module?label=Pull%20Requests&style=for-the-badge)](https://github.com/notnotmelon/parallel-module/pulls)

---

### Parallel

Parallel is a powerful new module effect provided by parallel modules. Parallel causes recipes to run multiple copies of their recipe at the same time. For example, a machine crafting iron gears with +300% parallel will craft __four gears each cycle__ using four times the iron.

This comes at a massive speed penalty, meaning most setups will need a careful balance between speed and parallel for maximum effect. Unlike other module penalties, this speed penalty __scales with quality__. A legendary tier 3 parallel module will reduce speed by -330%.

Parallel modules cannot be used in labs, beacons, mining drills, the recycler, or agricultural towers.

---

### Recipe limit

The parallel module works by creating many hidden recipe prototypes in the engine. You can expect that the number of recipes in your save will increase by roughly 3-5x. Unfortunately, the Factorio engine cannot support more than __65536__ recipes loaded at the same time.

If you are near the limit, this mod prints a warning in the chat. It will also stop adding parallel recipes and start banning parallel modules from some machines until you are under the limit again. This ensures that the game will at least always load.
Additionally, there are several startup settings to reduce the number of recipes added by this mod.

For context, with the full pY modpack and parallel module installed there are 49523 recipes on default parallel settings.

---

### Compatibility

This mod has extensive compatibility with the rest of the Factorio ecosystem.

- [Space age](https://wiki.factorio.com/Space_Age): Full compatibility. Module t3 is unlocked on Aquilo with cryogenic science.
- [Space exploration](https://mods.factorio.com/mod/space-exploration): Full compatibility. Modules up to t9 are added in the Space Exploration art style. Recipes are integrated into the naquium chain.
- [Secretas & Frozeta](https://mods.factorio.com/mod/secretas): Full compatibility. Module t4 is added and crafted from Frozeta gold.
- [Bobs, Angels, Seablock](https://mods.factorio.com/mod/bobmodules): Partial compatibility. Module graphics do not match with the Bobs Module graphics style. Otherwise fully functional.
- [Pyanodons](https://mods.factorio.com/mod/pymodpack): Full compatibility.
- [Ultracube](https://mods.factorio.com/mod/Ultracube): Not compatible.
- [Tier 4 Modules](https://mods.factorio.com/mod/modules-t4): Full compatibility. t4 parallel module is added, requiring quantum processors.
- [Krastorio 2](https://mods.factorio.com/mod/Krastorio2): Full compatibility.
- [Rigor Module](https://mods.factorio.com/mod/rigor-module): Partial compatibility. You cannot use parallel modules and rigor modules in the same machine. Otherwise fully functional.

Additionally, this mod will attempt to detect changes to the speed module recipes and apply those changes to the parallel module recipe.

---

### For modders

The API for this mod is designed to be intuitive. In general any speed, productivity, or effectivity prototype property can be replaced with a parallel property and parallel modules will use that definition.

You cannot allow parallel modules within labs, beacons, agricultural towers, or mining drills. This is because the module effect is handled completely by runtime scripting. If you require this feature, please submit a pull request.

For more details, see [API.md](https://github.com/notnotmelon/parallel-module/blob/main/API.md)

---

### Credits

This mod is largely inspired by [Rigor Module](https://mods.factorio.com/mod/rigor-module).
Huge thanks for thremtopod for pioneering this space!
