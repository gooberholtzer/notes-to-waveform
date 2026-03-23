# notes-to-waveform

An R script that converts musical notes to their frequencies, sums their sine waves, and saves a waveform plot to PDF.  It's interesting to see how notes that
sound resolved together like 1 and 5 notes (C and G for example) repeat the waveform quickly vs dissonant combinations.  This gives a "physical view" of what is
happening with intervals in music theory. 

## Requirements

- R (with base packages)

## Usage

```
./notes.r [--cycle] <note> [note ...]
```

### Options

| Option | Description |
|--------|-------------|
| `--cycle` | Show one full repeat of the combined wave instead of 6 cycles of the lowest note |

### Note Format

```
<letter>[accidental][octave]
```

- **letter** — A–G (case-insensitive)
- **accidental** — `#` for sharp, `b` for flat (optional)
- **octave** — integer (optional, defaults to 4)

Enharmonic equivalents are supported: `C#`/`Db`, `D#`/`Eb`, `E`/`Fb`, `F`/`E#`, `F#`/`Gb`, `G#`/`Ab`, `A#`/`Bb`, `B`/`Cb`.

## Examples

```sh
./notes.r A4              # A4 (440 Hz)
./notes.r C               # C4 (middle C, octave defaults to 4)
./notes.r F#5             # F-sharp 5
./notes.r Bb3             # B-flat 3
./notes.r Eb              # E-flat 4
./notes.r C4 E4 G4        # C major chord
./notes.r C Eb G          # C minor chord (octaves default to 4)
./notes.r --cycle C4 E4 G4  # show one full waveform repeat
```

## Output

The plot is saved to `my_note_view.pdf` in the working directory and opened automatically. The plot title shows each note with its resolved frequency (e.g. `C4 (261.63 Hz)  |  E4 (329.63 Hz)  |  G4 (392.0 Hz)`).

## How It Works

1. Each note string is parsed into letter, accidental, and octave.
2. Frequency is computed as `440 * 2^(semitones / 12)` relative to A4.
3. Sine waves for all notes are summed and normalized to `[-1, 1]`.
4. Without `--cycle`: 6 cycles of the lowest note's period are shown.
5. With `--cycle`: the duration covers one full repeat of the combined wave, found by computing the LCM of the rational approximations of the frequency ratios.
