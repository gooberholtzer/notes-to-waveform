#!/usr/bin/env Rscript

# Semitone offsets relative to A4 (440 Hz).
# Formula: freq = 440 * 2^((offset + (octave - 4) * 12) / 12)
# A4 check: offset["A"] + (4-4)*12 = 0 + 0 = 0 => 440 * 2^0 = 440 Hz
semitone_offsets <- c(
  "C"  = -9,
  "C#" = -8, "Db" = -8,
  "D"  = -7,
  "D#" = -6, "Eb" = -6,
  "E"  = -5, "Fb" = -5,
  "F"  = -4, "E#" = -4,
  "F#" = -3, "Gb" = -3,
  "G"  = -2,
  "G#" = -1, "Ab" = -1,
  "A"  =  0,
  "A#" =  1, "Bb" =  1,
  "B"  =  2, "Cb" =  2
)

note_to_freq <- function(note_str) {
    match <- regmatches(note_str, regexec("^([A-Ga-g])([#b]?)([0-9]*)$", note_str))[[1]]

    if (length(match) == 0) {
        stop(paste("Invalid note format:", note_str, "- examples: A4, Eb3, F#5, C4"))
    }

    letter     <- toupper(match[2])
    accidental <- match[3]
    octave     <- ifelse(match[4] == "", 4L, as.integer(match[4]))
    key        <- paste0(letter, accidental)

    if (!key %in% names(semitone_offsets)) {
        stop(paste("Invalid note:", key, "- use # for sharp, b for flat"))
    }

    semitones <- semitone_offsets[key] + (octave - 4) * 12
    440 * 2^(semitones / 12)
}

gcd_int <- function(a, b) if (b == 0L) a else gcd_int(b, a %% b)
lcm_int <- function(a, b) as.integer(a / gcd_int(a, b)) * b

# Approximate x as p/q with |x - p/q| < tol
to_rational <- function(x, tol = 2e-2) {
    for (q in 1:2000) {
        p <- round(x * q)
        if (abs(x - p / q) < tol) {
            g <- gcd_int(as.integer(p), as.integer(q))
            return(c(as.integer(p / g), as.integer(q / g)))
        }
    }
    c(as.integer(round(x * 2000)), 2000L)
}

# Duration for one full repeat of the combined wave
cycle_duration <- function(freqs) {
    f_min  <- min(freqs)
    fracs  <- lapply(freqs / f_min, to_rational)
    denoms <- sapply(fracs, `[`, 2)
    Reduce(lcm_int, denoms) / f_min
}

plot_notes <- function(note_strings, cycle = FALSE) {
    # Calculate frequencies for all notes
    freqs <- sapply(note_strings, note_to_freq)

    # Show 6 cycles of the lowest note, or one full repeat of the combined wave
    duration <- if (cycle) cycle_duration(freqs) else 6 / min(freqs)
    
    # Build sine wave, sum and normalize
    sample_rate <- 44100
    t           <- seq(0, duration, length.out = sample_rate * duration)
    wave        <- rowSums(sapply(freqs, function(f) sin(2 * pi * f * t)))
    wave        <- wave / max(abs(wave))
    
    # Build title — show full note name including resolved octave
    full_names <- sapply(note_strings, function(ns) {
        m <- regmatches(ns, regexec("^([A-Ga-g][#b]?)([0-9]*)$", ns))[[1]]
        oct <- ifelse(m[3] == "", "4", m[3])
        paste0(toupper(substring(m[2], 1, 1)), substring(m[2], 2), oct)
    })
    note_labels <- paste0(full_names, " (", round(freqs, 2), " Hz)")
    title_str   <- paste(note_labels, collapse = "  |  ")
   
    pdf("my_note_view.pdf" )

    xlab_str <- paste0("Time (seconds)  [", round(duration * 1000, 2), " ms shown]")

    plot(
        t, wave,
        type  = "l",
        col   = "steelblue",
        lwd   = 2,
        main  = title_str,
        xlab  = xlab_str,
        ylab  = "Amplitude",
        ylim  = c(-1.2, 1.2)
    )

    abline(h = 0, col = "gray", lty = 2)
    
    invisible(list(notes = note_strings, frequencies = freqs))

    dev.off()
    cat("Plot saved to:", file.path(getwd(), "my_note_view.pdf"), "\n")
    system(paste("open", shQuote(file.path(getwd(), "my_note_view.pdf"))))
}

args <- commandArgs(trailingOnly = TRUE)
cycle_mode <- "--cycle" %in% args
args <- args[args != "--cycle"]

if (length(args) == 0) {
    cat("Usage: notes.r [--cycle] <note> [note ...]\n")
    cat("\n")
    cat("Options:\n")
    cat("  --cycle    Show one full repeat of the combined wave instead of 6 cycles\n")
    cat("\n")
    cat("  Note format: <letter>[accidental][octave]\n")
    cat("    letter     - A-G (case-insensitive)\n")
    cat("    accidental - # for sharp, b for flat (optional)\n")
    cat("    octave     - integer (optional, defaults to 4)\n")
    cat("\n")
    cat("Examples:\n")
    cat("  notes.r A4          # A4 (440 Hz)\n")
    cat("  notes.r C           # C4 (middle C, octave defaults to 4)\n")
    cat("  notes.r F#5         # F-sharp 5\n")
    cat("  notes.r Bb3         # B-flat 3\n")
    cat("  notes.r Eb          # E-flat 4 (octave defaults to 4)\n")
    cat("  notes.r C4 E4 G4    # C major chord\n")
    cat("  notes.r C Eb G      # C minor chord (all default to octave 4)\n")
    cat("  notes.r --cycle C4 E4 G4  # show one full waveform repeat\n")
    quit(status = 1)
}
plot_notes(args, cycle = cycle_mode)
