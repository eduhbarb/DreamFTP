// Copyright (C) 2026 Synaelle
// SPDX-License-Identifier: AGPL-3.0-or-later
// The screens' colours, picked in Settings: DreamFTP's near-black and purple,
// or graphite and teal. The Dream look follows the accent (Settings' Colour
// row, or SITE COLOR from Baguette), the same way Baguette does: each colour
// takes the accent's hue, and a lightness that keeps its luminance, so text
// stays as easy to read as on the default purple. Teal keeps its own colours.

use crate::settings::DEFAULT_ACCENT;

pub type Color = u32; // 0xRRGGBB

#[derive(Clone, Copy, PartialEq)]
pub struct Palette {
    pub accent: Color,
    pub on_accent: Color, // text on the accent
    pub highlight: Color,
    pub soft: Color,
    pub bg: Color,
    pub blob: Color,
    pub card: Color,
    pub track: Color,
    pub selected: Color,
    pub border: Color,
    pub text: Color,
    pub dim: Color,
}

/// the colours the Settings tab steps through, the same as Baguette's, each as
/// light as the default purple (Custom is any other colour Baguette set)
pub const PRESETS: [(&str, Color); 8] = [
    ("Purple", DEFAULT_ACCENT),
    ("Indigo", 0x5865f2),
    ("Blue", 0x3d8bfd),
    ("Teal", 0x20908a),
    ("Green", 0x2b9349),
    ("Amber", 0xb6721c),
    ("Orange", 0xce622d),
    ("Pink", 0xcd53a6),
];

/// the looks the Settings tab offers
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum Theme {
    Dream, // DreamFTP's own: near-black and purple
    Teal,  // graphite and teal
    Sharp, // the Dream look's colours, sharp, in Hanken Grotesk
}

pub const THEMES: [Theme; 3] = [Theme::Dream, Theme::Teal, Theme::Sharp];

impl Theme {
    pub fn name(self) -> &'static str {
        match self {
            Theme::Teal => "Teal",
            Theme::Sharp => "Sharp",
            Theme::Dream => "Dream",
        }
    }

    /// its value in settings.ini
    pub fn key(self) -> &'static str {
        match self {
            Theme::Teal => "teal",
            Theme::Sharp => "sharp",
            Theme::Dream => "dream",
        }
    }

    fn palette(self) -> Palette {
        match self {
            Theme::Teal => TEAL,
            Theme::Sharp => DREAM,
            Theme::Dream => DREAM,
        }
    }
}

/// graphite and teal
const TEAL: Palette = Palette {
    accent: 0x3cc8bd,
    on_accent: 0x062320,
    highlight: 0x8ee6de,
    soft: 0xc9cdd3,
    bg: 0x121316,
    blob: 0x191b1f,
    card: 0x1b1d21,
    track: 0x24262b,
    selected: 0x17302f,
    border: 0x2e3238,
    text: 0xf1f2f4,
    dim: 0x9a9fa8,
};

/// near-black and purple, DreamFTP's own look
const DREAM: Palette = Palette {
    accent: DEFAULT_ACCENT,
    on_accent: 0x14061f, // dark: white on this purple is too faint
    highlight: 0xcbb0f5, // the accent made lighter, for small text on the track and selection
    soft: 0xe6dcf5,
    bg: 0x08060d,
    blob: 0x160d24,
    card: 0x150e21,
    track: 0x1e1530,
    selected: 0x2c1a45,
    border: 0x2e2342,
    text: 0xf4eefc,
    dim: 0x9e93b0,
};

/// (hue in degrees, saturation, lightness), as Baguette's toHsl
fn to_hsl(c: Color) -> (f64, f64, f64) {
    let (r, g, b) = (((c >> 16) & 255) as f64 / 255.0, ((c >> 8) & 255) as f64 / 255.0, (c & 255) as f64 / 255.0);
    let (max, min) = (r.max(g).max(b), r.min(g).min(b));
    let l = (max + min) / 2.0;
    if max == min {
        return (0.0, 0.0, l);
    }
    let d = max - min;
    let s = if l > 0.5 { d / (2.0 - max - min) } else { d / (max + min) };
    let h = if max == r {
        (g - b) / d + if g < b { 6.0 } else { 0.0 }
    } else if max == g {
        (b - r) / d + 2.0
    } else {
        (r - g) / d + 4.0
    };
    (h * 60.0, s, l)
}

/// HSL (hue in degrees, saturation and lightness 0 to 1) to RGB
fn from_hsl(h: f64, s: f64, l: f64) -> Color {
    let h = h.rem_euclid(360.0);
    let a = s * l.min(1.0 - l);
    let f = |n: f64| {
        let k = (n + h / 30.0) % 12.0;
        let v = l - a * (k - 3.0).min(9.0 - k).clamp(-1.0, 1.0);
        ((v * 255.0).round() as u32).min(255)
    };
    f(0.0) << 16 | f(8.0) << 8 | f(4.0)
}

/// the WCAG contrast ratio of two colours, 1 to 21
pub fn contrast(a: Color, b: Color) -> f64 {
    let (a, b) = (luminance(a), luminance(b));
    (a.max(b) + 0.05) / (a.min(b) + 0.05)
}

/// WCAG relative luminance
fn luminance(c: Color) -> f64 {
    let lin = |v: u32| {
        let v = (v & 255) as f64 / 255.0;
        if v <= 0.04045 { v / 12.92 } else { ((v + 0.055) / 1.055).powf(2.4) }
    };
    0.2126 * lin(c >> 16) + 0.7152 * lin(c >> 8) + 0.0722 * lin(c)
}

/// the colour of hue h and saturation s whose luminance is `target` (lightness found by bisection)
fn with_luminance(h: f64, s: f64, target: f64) -> Color {
    let (mut lo, mut hi) = (0.0, 1.0);
    for _ in 0..40 {
        let mid = (lo + hi) / 2.0;
        if luminance(from_hsl(h, s, mid)) < target {
            lo = mid;
        } else {
            hi = mid;
        }
    }
    from_hsl(h, s, (lo + hi) / 2.0)
}

impl Palette {
    /// the look's palette; the Dream one on another accent than the default
    /// takes the accent's hue, as light (in luminance) as the default's colours
    pub fn for_accent(theme: Theme, accent: Color) -> Palette {
        let d = theme.palette();
        if theme == Theme::Teal || accent == DEFAULT_ACCENT {
            return d;
        }
        let (h, sat, _) = to_hsl(accent);
        let base = to_hsl(DEFAULT_ACCENT).1;
        let follow = |c: Color| {
            let (_, s0, _) = to_hsl(c);
            // a greyer accent gives greyer surfaces
            with_luminance(h, s0 * (sat / base).min(1.0), luminance(c))
        };
        Palette {
            accent: with_luminance(h, sat, luminance(d.accent)),
            on_accent: d.on_accent,
            highlight: follow(d.highlight),
            soft: follow(d.soft),
            bg: follow(d.bg),
            blob: follow(d.blob),
            card: follow(d.card),
            track: follow(d.track),
            selected: follow(d.selected),
            border: follow(d.border),
            text: follow(d.text),
            dim: follow(d.dim),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_round_trips() {
        // the default colours come back unchanged on their own hue
        for c in [
            0x3cc8bd, 0x8ee6de, 0x24262b, 0x17302f, 0x2e3238, 0xf1f2f4, 0xe44c3e, 0xe6dfd8, 0x1f1c1b, 0x3a1915,
            0x2e2a28, 0x9a918a,
        ] {
            let (h, s, l) = to_hsl(c);
            let back = from_hsl(h, s, l);
            let diff = |s: u32| ((back >> s) & 255).abs_diff((c >> s) & 255);
            assert!(diff(16) <= 1 && diff(8) <= 1 && diff(0) <= 1, "{c:06x} -> {back:06x}");
        }
        for t in THEMES {
            assert!(Palette::for_accent(t, DEFAULT_ACCENT) == t.palette());
        }
    }

    #[test]
    fn accents_keep_the_contrast() {
        // every preset's colours are as light as the default purple's, and Teal ignores the accent
        let base = Palette::for_accent(Theme::Dream, DEFAULT_ACCENT);
        for (name, c) in PRESETS {
            let p = Palette::for_accent(Theme::Dream, c);
            let pairs = [
                (p.accent, base.accent),
                (p.text, base.text),
                (p.dim, base.dim),
                (p.bg, base.bg),
                (p.card, base.card),
                (p.highlight, base.highlight),
            ];
            for (got, want) in pairs {
                let (a, b) = (luminance(got), luminance(want));
                assert!((a - b).abs() <= 0.01 + 0.03 * b, "{name}: {got:06x} vs {want:06x}");
            }
            assert!(Palette::for_accent(Theme::Teal, c) == Palette::for_accent(Theme::Teal, DEFAULT_ACCENT));
            // small text in the highlight, on the track and the selection
            assert!(contrast(p.highlight, p.track) >= 4.5 && contrast(p.highlight, p.selected) >= 4.5, "{name}");
        }
    }
}
