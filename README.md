<!---
![GitHub Logo](/bw-assets/bw-logo.png)
--->

# T6 Bot Warfare
Bot Warfare is a GSC mod for the [PlutoniumT6 project](https://plutonium.pw/).

## Installation

0. Make sure that [PlutoniumT6](https://plutonium.pw/docs/install/) is installed, updated and working properly.
 - Download [this repository](https://github.com/ineedbots/t6_bot_warfare/archive/refs/heads/master.zip).
1. Open the Bot Warfare archive you downloaded, then open the `t6_bot_warfare-master` folder.
2. Drag the `scripts` folder found inside to `%LOCALAPPDATA%\Plutonium\storage\t6` folder.
3. The mod is now installed, now run your game.
4. The mod should be loaded! Now go start a map and play!

## Documentation

### DVARs

| Dvar                             | Description                                                                                 | Default Value |
|----------------------------------|---------------------------------------------------------------------------------------------|--------------:|
| bots_main                        | Enable this mod.                                                                            | 1             |
| bots_main_waitForHostTime        | How many seconds to wait for the host player to connect before adding bots to the match.    | 10            |
| bots_main_kickBotsAtEnd          | Kick the bots at the end of a match.                                                        | 0             |
| bots_manage_add                  | Amount of bots to add to the game, once bots are added, resets back to `0`.                 | 0             |
| bots_manage_fill                 | Amount of players/bots (look at `bots_manage_fill_mode`) to maintain in the match.          | 0             |
| bots_manage_fill_mode            | `bots_manage_fill` players/bots counting method.<ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots.</li></ul> | 0 |
| bots_manage_fill_kick            | If the amount of players/bots in the match exceeds `bots_manage_fill`, kick bots until no longer exceeds. | 0     |
| bots_manage_fill_spec            | If when counting players for `bots_manage_fill` should include spectators.                  | 1             |
| bots_team                        | One of `autoassign`, `allies`, `axis`, `spectator`, or `custom`. What team the bots should be on. | autoassign |
| bots_team_amount                 | When `bots_team` is set to `custom`. The amount of bots to be placed on the axis team. The remainder will be placed on the allies team. | 0 |
| bots_team_force                  | If the server should force bots' teams according to the `bots_team` value. When `bots_team` is `autoassign`, unbalanced teams will be balanced. This dvar is ignored when `bots_team` is `custom`. | 0     |
| bots_team_mode                   | When `bots_team_force` is `true` and `bots_team` is `autoassign`, players/bots counting method. <ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots</li></ul> | 0 |
| bots_skill                       | Bots' difficulty.<ul><li>`0` - Easiest difficulty for all bots.</li><li>`1` and `2` - Between easy and hard difficulty for all bots.</li><li>`3` - The hardest difficulty for all bots.</li></ul> | 0 |
| bots_loadout_rank                | What rank to set the bots.<ul><li>`-1` - Average of all players in the match.</li><li>`0` - All random.</li><li>`1` or higher - Sets the bots' rank to this.</li></ul> | -1 |
| bots_loadout_prestige            | What prestige to set the bots.<ul><li>`-1` - Same as host player in the match.</li><li>`-2` - All random.</li><li>`0` or higher - Sets the bots' prestige to this.</li></ul> | -1 |
| bots_play_nade                   | If the bots can grenade.                                                                       | 1          |
| bots_play_jumpdrop               | If the bots can jump/drop shot.                                                                | 1          |
| bots_play_aim                    | If the bots can aim.                                                                           | 1          |
