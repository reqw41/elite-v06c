# Сравнение версий Elite на 6502

Источник: https://elite.bbcelite.com/compare/feature_comparison.html (Mark Moxon). Таблица извлечена скриптом
`tools/analysis/bbc_features.py`, без правок.

| Feature | Cassette | Disc | Electron | 6502SP | C64 | Apple II | Master | NES |
|---|---|---|---|---|---|---|---|---|
| Release year | 1984 | 1984 | 1984 | 1985 | 1985 | 1986 | 1986 | 1991 |
| Ship types1 | 13 | 31 | 11 | 33 | 33 | 32 | 33 | 33 |
| Thargoids, Thargons | Yes | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Dodo space station | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Cougar | No | No | No | Yes | Yes | No | Yes | Yes |
| Cougar has a cloaking device | n/a | n/a | n/a | No | Yes | n/a | Yes | Yes |
| Rock hermits | No | No | No | Yes | Yes | Yes | Yes | Yes |
| Distinct2 ship designs | 12 | 29 | 10 | 30 | 30 | 29 | 30 | 30 |
| Max. ships in the local bubble3 | 10 | 10 | 10 | 18 | 8 | 6 | 10 | 6 |
| Max. cops in the local bubble | 4 | 4 | 3 | 7 | 4 | 4 | 6 | 4 |
| Bytes in each ship's data block | 36 | 37 | 36 | 37 | 37 | 37 | 37 | 37 |
| Enhanced AI and spawning (NEWB) | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Ships that Anacondas can spawn | n/a | Worm | n/a | WormSidewinder | WormSidewinder | WormSidewinder | WormSidewinder | WormSidewinder |
| Colours in the space view | 2 | 2 | 2 | 4 | 2 | 2 | 4 | 2 |
| Colours in the dashboard | 4 | 4 | 2 | 8 | 16 | 6 | 8 | 8 |
| Flashing dashboard indicators | Yes | Yes | No | Yes | Yes | Yes | Yes | No |
| Ship colours in the 3D scanner | 2 | 2 | 1 | 6 | 3 | 5 | 6 | 4 |
| Dot height in the 3D scanner (pixels) | 2 | 2 | 2 | 2 | 2 | 1 | 1 | 1 |
| Compass dot (in front) | Thick yellow | Thick yellow | Thick white | Thick white | Thick yellow | Thin white | Thick yellow | Green dot |
| Compass dot (behind) | Thin green | Thin green | Thin white | Thin green | Thin green | Thick white | Thin green | Cream circle |
| Space view height (pixels) | 192 | 192 | 192 | 192 | 144 | 136 | 192 | 157 |
| Space view width (pixels) | 256 | 256 | 256 | 256 | 260 | 259 | 256 | 256 |
| Dashboard height (pixels) | 56 | 56 | 56 | 56 | 56 | 56 | 56 | 72 |
| Dashboard width (pixels) | 128 | 128 | 256 | 128 | 128 | 259 | 128 | 256 |
| Escape pod colour scheme4 | Palette | Palette | No | Border | No | No | Border | No |
| Mining lasers and asteroid mining | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Military lasers | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Crosshair colour varies with laser type | No | No | No | No | Yes | Yes | Yes | Yes |
| Crosshair design varies with laser type | No | No | No | No | Yes | No | No | Yes |
| Enemy laser colour | White | White | White | Red | White | White | Cyan | Cyan |
| Proper docking computer | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Sun, fuel scooping, cabin temperature | Yes | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Planet meridians and craters | Yes | Yes | No | Yes | Yes5 | No | Yes | Yes |
| Extended text tokens | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Extended system descriptions | No | Yes6 | No | Yes | Yes | Yes | Yes | Yes |
| Missions | No | 2 | No | 2 | 3 | 2 | 2 | 3 |
| Energy bomb kills Constrictor | n/a | Yes | n/a | No | No | No | No | No |
| Energy bomb kills Thargoids | Yes | Yes | n/a | Yes | No | No | No | No |
| Energy bomb graphical effect | Flash | Flash | No | No | Lightning | Lightning | Lightning | Bitplanes |
| "Press Fire or Space" ship | Mamba | Krait | Mamba | Asp Mk II | Adder | Sidewinder | Cougar | n/a |
| Search for systems by name | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Key to move chart pointer quickly | No | SHIFT | No | SHIFT | RETURN | No | SHIFT | No |
| Buy/sell specific amounts of cargo | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Buy all available cargo with "Y" | No | Yes | No | Yes | Yes | Yes | Yes | No |
| Display ship hangar on docking | No | Yes | No | Yes | No | No | Yes | Yes |
| Launch tunnel colour | White | White | White | Yellow | White | White | White | Cyan |
| Disc access menu | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Revert7 to default commander | No | No | No | No | Yes | Yes | Yes | No |
| Fractional kill counts | No | No | No | No | Yes | Yes | Yes | Yes |
| Kill count varies by ship type | No | No | No | No | Yes | Yes | Yes | Yes |
| Kill count for cargo, asteroids, escape pods, Thargons | No | Yes | No | Yes | Yes | Yes | Yes | Yes |
| "S/E" indicator width (in space view pixels) | 6 | 6 | 7 | 8 | 8 | 7 | 8 | n/a |
| Fuel goes red when low | Yes | Yes | No | No | No | No | No | No |
| Volume control | No | No | No | No | No | No | Yes | No |
| Sound effects | Standard | Standard | Basic | Standard | Enhanced | Basic | Enhanced | Enhanced |
| Laser sound attack phase amplitude8 | 112 | 126 | n/a | 126 | n/a | n/a | n/a | n/a |
| Save screenshot | No | No | No | Yes | No | No | No | No |
| Send trade screens to printer | No | No | No | Yes | No | No | No | No |
| Logarithm-based maths routines | No | No | No | Yes | Yes | Yes | Yes | Yes |
| Hostile ships spawning distance | 32 | 25 | 32 | 25 | 25 | 25 | 25 | 25 |
| Galactic hyperspace counts down from | 15 | 15 | 15 | 2 | 2 | 2 | 2 | 2 |
| Hyperspace countdown text column | 5 | 6 | 5 | 6 | 6 | 6 | 6 | 6 |
| Rings in the hyperspace tunnel | 16 | 16 | 16 | 8 | 8 | 8 | 8 | 8 |
| Witchspace | Yes | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Launch escape pod in witchspace | Fatal | Yes | n/a | No | No | No | No | No |
| Thargoids in witchspace | 4 | 4 | n/a | 4 | 4 | 3 | 3 | 3 |
| Docking check9 #3 | Yes | No | Yes | No | No | No | No | No |
| Docking check9 #4 vector | Station | Planet | Station | Planet | Planet | Planet | Planet | Planet |
| Docking check9 #4 angle | 22.0° | 26.3° | 22.0° | 22.0° | 22.0° | 22.0° | 22.0° | 22.0° |
| Medium circle radius range10 | 8-60 | 8-60 | 9+ | 4-50 | 8-60 | 8-60 | 8-60 | 8-60 |
| Explosion particles per vertex | 15 | 15 | 7 | 15 | 7 | 7 | 7 | 7 |
| Stardust particles | 18 | 18 | 10 | 18 | 12 | 12 | 20 | 20 |
| Top laser line vertical offset11 | 0 | 0 | 0 | 1 | 0 | 0 | 2 | 0 |
| In-flight message position | Column 9 | Column 9 | Column 9 | Centred | Centred | Centred | Centred | Centred |
| Max. junk shown on our death | 4 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| Version bit number in save file12 | 1 | 2 or 5 | 3 | 2 | 6 | 3 | 3 | n/a |
| "Star Wars" scroll text and demo | No | No | No | Yes | No | No | No | Yes |
| Random Saturn on load screen | Yes | Yes | Yes | Yes | n/a | n/a | No | n/a |
| Title banners on load screen | Yes | Yes | Yes | Yes | n/a | n/a | No | n/a |
| Saturn planet dot counts | 1280 | 768 | 1280 | 768 | n/a | n/a | 768 | n/a |
| Saturn ring dot counts | 1280 | 819 | 1280 | 819 | n/a | n/a | 819 | n/a |
| Saturn dot plotting logic | OR | Overwrite | OR | Overwrite | n/a | n/a | Overwrite | n/a |
| TINA hook13 | No | No | No | Yes | No | No | No | No |
| Joystick support14 | Yes | Yes | No | Yes | Yes | Yes | Yes | n/a |
| Bitstik support15 | No | Yes | No | Yes | n/a | n/a | Yes | n/a |
| Loading pause on launch/dock | No | Yes | No | No | No | No | No | No |
| CPU | 6502 | 6502 | SY6502A | 65C02 | 6510 | 6502 | 65SC12 | 2A03/2A07 |
| CPU speed (PAL) | 2 MHz | 2 MHz | 1-2 MHz | 3 MHz | 0.985 MHz | n/a | 2 MHz | 1.66 MHz |
| CPU speed (NTSC) | n/a | n/a | n/a | n/a | 1.023 MHz | 1.023 MHz | n/a | 1.79 MHz |
| Size of loader binaries (bytes)16 | 5,426 | 8,448 | 4,864 | 6,557 | 19,217 | 8,552 | 721 | 16 |
| Size of main binaries (bytes)17 | 20,712 | 39,994 | 19,200 | 45,253 | 33,977 | 38,504 | 44,616 | 131,072 |
| Total size of all binaries (bytes)18 | 26,138 | 48,442 | 24,064 | 51,810 | 53,194 | 47,056 | 45,337 | 131,088 |
| Total instruction count | 9,414 | 16,598 | 8,669 | 12,960 | 13,052 | TBC | 12,327 | 22,237 |
