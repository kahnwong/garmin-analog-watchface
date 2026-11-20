# Font Generation

If you want to do it manually:
1. Run `./convert.sh`.
2. Go to <https://snowb.org/> and add pngs to glyps. Assign glyph character as `0`, `1`, and `2` (per filename).
3. Set font size to `30`.
4. Export as `BMFont TEXT`.
5. Open `.fnt` file and change `page=-1` for first `char` to `page=0`.

Otherwise run `uv run fonts`.

---

Sprites are obtained from <https://pokemondb.net/sprites/>.
