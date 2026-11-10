# Quest Drop Rates

This addon displays quest-item drop percentages on creature tooltips. It targets
WoW Forever's `16001` interface and works independently of the Questie quest
helper.

The addon requires **QuestieDB**, the standalone data provider, not Questie. It
reads the Forever drop-rate and correction tables from QuestieDB and appends a
rate to matching item lines, including lines added by other quest addons.

## Installation

Install QuestieDB, then place the `QuestDropRates` folder in
`World of Warcraft/_classic_/Interface/AddOns/` and enable it in the AddOns list.

## License

This addon is available under the MIT License; see [LICENSE](LICENSE).

## Releases

Releases are published automatically when a version tag is pushed. Update the
`## Version` value in `QuestDropRates.toc`, then push a matching tag such as
`v0.1.0`. The workflow checks that the tag and addon versions match, packages
the addon folder as a ZIP, and attaches it to a GitHub Release.
