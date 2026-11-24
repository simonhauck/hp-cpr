# Changelog

## [0.4.0](https://github.com/simonhauck/hp-cpr/compare/v0.3.0...v0.4.0) (2026-11-24)


### Features

* **amiodaron:** show the card with a not-recommended state ([#51](https://github.com/simonhauck/hp-cpr/issues/51)) ([72912db](https://github.com/simonhauck/hp-cpr/commit/72912db2be9c5a3f66a4c9f9471cf16cc45a9147))
* **analysephase:** remove the skip button ([#82](https://github.com/simonhauck/hp-cpr/issues/82)) ([3646b03](https://github.com/simonhauck/hp-cpr/commit/3646b0343c14ed19f56c9a0eee9988e07f7c5802))
* **branding:** add the app icon and launch screen ([#110](https://github.com/simonhauck/hp-cpr/issues/110)) ([b6b7c8e](https://github.com/simonhauck/hp-cpr/commit/b6b7c8e0e68b51ac46e6a52f35faf6090c89c80e))
* **einsatzlog:** show the case date ([#69](https://github.com/simonhauck/hp-cpr/issues/69)) ([22dccdc](https://github.com/simonhauck/hp-cpr/commit/22dccdc13584e32f0b64c51f569c67089b75a2fb))
* **medikamente:** emphasize due doses and place cards beside the phase ([#83](https://github.com/simonhauck/hp-cpr/issues/83)) ([2e3d1d7](https://github.com/simonhauck/hp-cpr/commit/2e3d1d7fee48c2972ee50cac31c0bd31d60de7ea))
* **protokoll:** allow correcting structural events during a running case ([#89](https://github.com/simonhauck/hp-cpr/issues/89)) ([16b0e29](https://github.com/simonhauck/hp-cpr/commit/16b0e29ed1a5ca44721f566d58f65e66b84acc1d))
* **reanimationsfall:** ask before leaving a running case ([#73](https://github.com/simonhauck/hp-cpr/issues/73)) ([7837940](https://github.com/simonhauck/hp-cpr/commit/783794035933bb6c91e5e800e63a056632a8d698))
* **reanimationsfall:** correct the Startzeit and Übernahme ([#85](https://github.com/simonhauck/hp-cpr/issues/85)) ([11b44e7](https://github.com/simonhauck/hp-cpr/commit/11b44e7ec3d499405cfa1f98f64240e693387284))
* **reanimationsfall:** drop the undo notice when entering the Analysephase ([#106](https://github.com/simonhauck/hp-cpr/issues/106)) ([c623695](https://github.com/simonhauck/hp-cpr/commit/c62369510d2f167e64fa440aa88e9d89bb85366a))
* **reanimationsfall:** group the Aktionen sheet ([#68](https://github.com/simonhauck/hp-cpr/issues/68)) ([e5697d7](https://github.com/simonhauck/hp-cpr/commit/e5697d78fb64ae232c90d9671e8f3449057945d8))
* **reanimationsfall:** offer undo after one-tap entries ([#103](https://github.com/simonhauck/hp-cpr/issues/103)) ([28aee5e](https://github.com/simonhauck/hp-cpr/commit/28aee5e6e4a8b8e6a4e6a67f4f2a62c0c77fdd82))
* **reanimationsfall:** record Vorbehandlung counts ([#90](https://github.com/simonhauck/hp-cpr/issues/90)) ([45bf9f1](https://github.com/simonhauck/hp-cpr/commit/45bf9f152b748be2306f85eefe26a334e614af21))
* **reanimationsfall:** show Vorbehandlung erfassen in the action bar ([#102](https://github.com/simonhauck/hp-cpr/issues/102)) ([a6d5883](https://github.com/simonhauck/hp-cpr/commit/a6d58833fc7995a6e67758a1e39db0aa2ddd3f6f))
* **signals:** vibrate when actions become due ([#84](https://github.com/simonhauck/hp-cpr/issues/84)) ([1c127ae](https://github.com/simonhauck/hp-cpr/commit/1c127ae5e6b1d769aba629bdc3383f4998466ee4))
* **summary:** break out the Vorbehandlung share ([#91](https://github.com/simonhauck/hp-cpr/issues/91)) ([09c787a](https://github.com/simonhauck/hp-cpr/commit/09c787ad3f669e710fb56de73c1bcf066e211ada))


### Bug Fixes

* **aktionen:** list Messwerte under Erfassen ([#86](https://github.com/simonhauck/hp-cpr/issues/86)) ([c666323](https://github.com/simonhauck/hp-cpr/commit/c666323c08801e8cf3ec6615e5a285c15ad12ad9))
* **medikamente:** align the Adrenalin and Amiodaron cards ([#74](https://github.com/simonhauck/hp-cpr/issues/74)) ([f977620](https://github.com/simonhauck/hp-cpr/commit/f97762036d485f0230fe3c1660a67f3f890db4f5))
* **rhythmusanalyse:** skip the repeated category step ([#72](https://github.com/simonhauck/hp-cpr/issues/72)) ([4d091ad](https://github.com/simonhauck/hp-cpr/commit/4d091ada6b1eb2819c7c460c838c7dfe89f0d7bb))
* **summary:** remove duplicates and sort Messwerte consistently ([#71](https://github.com/simonhauck/hp-cpr/issues/71)) ([7fe1dae](https://github.com/simonhauck/hp-cpr/commit/7fe1daeea01007614bd43de2dcc8e79d54d2a6b8))
* **ui:** align the start page action buttons ([#52](https://github.com/simonhauck/hp-cpr/issues/52)) ([44c2df7](https://github.com/simonhauck/hp-cpr/commit/44c2df74e4223666403a965af17dcfff3281ede0))
* **ui:** consistent form fields, dialog buttons and chips ([#75](https://github.com/simonhauck/hp-cpr/issues/75)) ([e4c9f23](https://github.com/simonhauck/hp-cpr/commit/e4c9f23537a952625c60b6b78c3eb8fde03525f3)), closes [#61](https://github.com/simonhauck/hp-cpr/issues/61)
* **ui:** consistent time formats and wording ([#77](https://github.com/simonhauck/hp-cpr/issues/77)) ([5e5a797](https://github.com/simonhauck/hp-cpr/commit/5e5a7972ac5b82c5e4c0ed5b7483f5b62f1f7531))
* **ui:** wrap action button labels instead of shrinking them ([#108](https://github.com/simonhauck/hp-cpr/issues/108)) ([f249825](https://github.com/simonhauck/hp-cpr/commit/f2498251803fc64d5cdfea628776ad66633df11f))

## [0.3.0](https://github.com/simonhauck/hp-cpr/compare/v0.2.0...v0.3.0) (2026-11-06)


### Features

* **ui:** add responsive phone layout ([#50](https://github.com/simonhauck/hp-cpr/issues/50)) ([dd0f0ca](https://github.com/simonhauck/hp-cpr/commit/dd0f0ca7be2aa3940325b3a8219038f053348a2f))


### Bug Fixes

* **ci:** build release artifacts from the tag ([#47](https://github.com/simonhauck/hp-cpr/issues/47)) ([d202d8c](https://github.com/simonhauck/hp-cpr/commit/d202d8ca06016c8543d0227efc338ba8fc6d1867))

## [0.2.0](https://github.com/simonhauck/hp-cpr/compare/v0.1.0...v0.2.0) (2026-11-01)


### Features

* **adrenalin:** track the 3-5 minute Zeitfenster ([#24](https://github.com/simonhauck/hp-cpr/issues/24)) ([65014b8](https://github.com/simonhauck/hp-cpr/commit/65014b8495202d0b05ebc1853d5a65c69a2cfc20)), closes [#5](https://github.com/simonhauck/hp-cpr/issues/5)
* **amiodaron:** surface the contextual Amiodaron hint ([#27](https://github.com/simonhauck/hp-cpr/issues/27)) ([dfb1f46](https://github.com/simonhauck/hp-cpr/commit/dfb1f46f228fe5e7418b868765843b3da5dc2577))
* **analysephase:** add rhythm analysis and settings ([#11](https://github.com/simonhauck/hp-cpr/issues/11)) ([eaecad3](https://github.com/simonhauck/hp-cpr/commit/eaecad3968164e8dc7652c677657db1958f30ab5))
* **einsatzlog:** persist cases and add the local Einsatzlog ([#29](https://github.com/simonhauck/hp-cpr/issues/29)) ([ba3b259](https://github.com/simonhauck/hp-cpr/commit/ba3b2599830e35504466320368454419177af17f))
* **menu:** add app menu, legal pages, and MIT license ([#26](https://github.com/simonhauck/hp-cpr/issues/26)) ([24f34a5](https://github.com/simonhauck/hp-cpr/commit/24f34a5042838bc349a81ce5cf69a8e1e8c60912))
* **messwerte:** record measurements and free-text notes ([#30](https://github.com/simonhauck/hp-cpr/issues/30)) ([70a786f](https://github.com/simonhauck/hp-cpr/commit/70a786f70d1ef38b8c58a9c706c1d91db2140b1e))
* **reanimationsfall:** add demo mode ([#44](https://github.com/simonhauck/hp-cpr/issues/44)) ([fbc677d](https://github.com/simonhauck/hp-cpr/commit/fbc677d577d8ac49bc51ca781465933b73534a43))
* **reanimationsfall:** add Druckphase restart action ([#43](https://github.com/simonhauck/hp-cpr/issues/43)) ([e34c9d3](https://github.com/simonhauck/hp-cpr/commit/e34c9d328690cc00c377077473c3a633b0ab56c7))
* **reanimationsfall:** add guided analysis domain ([#39](https://github.com/simonhauck/hp-cpr/issues/39)) ([4ebe725](https://github.com/simonhauck/hp-cpr/commit/4ebe7255937f3f3ea5f249bc9965c27571fdcf4c))
* **reanimationsfall:** add guided Rhythmusanalyse wizard ([#41](https://github.com/simonhauck/hp-cpr/issues/41)) ([da8d123](https://github.com/simonhauck/hp-cpr/commit/da8d1233d98bc21b56d0aac28cd93dade53053c7))
* **reanimationsfall:** add phase strip and Aktionen entry ([#40](https://github.com/simonhauck/hp-cpr/issues/40)) ([a70adcb](https://github.com/simonhauck/hp-cpr/commit/a70adcba8ad94ae4139f0e542ec9b8afe9c26b38))
* **reanimationsfall:** record ROSC, rearrest, and end with summary ([#28](https://github.com/simonhauck/hp-cpr/issues/28)) ([b4520b6](https://github.com/simonhauck/hp-cpr/commit/b4520b67e4df77a0915d1b065fb7b3ea3ab008af))
* **schock:** record shocks with energy and undo ([#23](https://github.com/simonhauck/hp-cpr/issues/23)) ([e002a69](https://github.com/simonhauck/hp-cpr/commit/e002a69c10a4c2d8435e968d6873b9276e4933bd)), closes [#4](https://github.com/simonhauck/hp-cpr/issues/4)
* **timer:** start a Reanimationsfall and run the Druckphase ([#10](https://github.com/simonhauck/hp-cpr/issues/10)) ([fce5ac3](https://github.com/simonhauck/hp-cpr/commit/fce5ac364b6dec4a84c1f5cffa0af4b6ce18fe9a))
* **ui:** move Messwerte and Notiz into Aktionen ([#42](https://github.com/simonhauck/hp-cpr/issues/42)) ([b92beb2](https://github.com/simonhauck/hp-cpr/commit/b92beb2b6ee89f22c0e43232dc2a37ea192cd323))
* **ui:** polish case flow and app details ([#45](https://github.com/simonhauck/hp-cpr/issues/45)) ([60d034c](https://github.com/simonhauck/hp-cpr/commit/60d034cde5c322150138281f862dbe4382da9fbf))


### Bug Fixes

* **reanimationsfall:** keep corrections append-only and disable drugs during ROSC ([#31](https://github.com/simonhauck/hp-cpr/issues/31)) ([de1f993](https://github.com/simonhauck/hp-cpr/commit/de1f993b70de074c5931a934cb339a0253d14984))
