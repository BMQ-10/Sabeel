<p align="center"><img src="icon.svg" width="120" height="120" alt="Sabeel icon"></p>

<h1 align="center">سبيل Sabeel — Your Path Into Islam</h1>

<p align="center">A private, offline reference app for new Muslims: essentials, prayer times, Qibla direction, wudhu &amp; salah, fiqh, Ramadan, Hajj, duas, and interactive quizzes.</p>

---

## Features

- **Islamic Essentials** — Core beliefs, pillars, and articles of faith with Arabic and English
- **Prayer Times** — Accurate calculation with latitude/longitude input and manual override
- **Qibla Direction** — Compass-based Qibla finder from any location
- **Wudhu &amp; Salah Practice** — Step-by-step guided practice with real reciter audio and checklists
- **Fiqh Overview** — The four Sunni schools of law with shared and differing positions
- **Ramadan &amp; Hajj** — Obligations, categories, FAQs, and step-by-step guides
- **Duas Collection** — Hisnul Muslim supplications with Arabic, transliteration, translation, and audio
- **Quran Reader** — Browse daily verses with multiple reciters, play/pause, and speed control
- **Interactive Quiz** — Test knowledge across topics with scoring and streaks
- **Tappable Glossary** — Key Islamic terms become tappable inline, showing Arabic, meaning, and pronunciation
- **Offline-Ready** — Single HTML file, works without internet (reciter audio requires connection)
- **PWA Support** — Installable on mobile and desktop, dark/light theme support

## Getting Started

Open `Sabeel.html` in any modern browser. No server or build step required.

```bash
# Clone the repository
git clone https://github.com/BMQ-10/Sabeel

# Open directly
open Sabeel.html
```

## File Structure

```
.
├── Sabeel.html    # Complete app (HTML + CSS + JS, ~7000 lines, single file)
├── icon.svg       # App icon (lantern with glowing flame)
├── README.md      # This file
└── .gitignore
```

## Tech Stack

- **Pure HTML/CSS/JS** — Zero dependencies, no build tools, no frameworks
- **Quran.com API** — Verse data, reciter audio, and word-level timing segments
- **Hisnul Muslim** — Human-recorded supplication audio
- **Web APIs** — Geolocation, Speech Synthesis, Audio, IntersectionObserver, Clipboard

## Reciters

The Quran reader supports 7 reciters with real recordings from the Islamic Network CDN:

| Reciter | ID |
|---|---|
| Maher Al-Muaiqly | `ar.mahermuaiqly` |
| Mishary Alafasy | `ar.alafasy` |
| Saud Al-Shuraim | `ar.saoodshuraym` |
| Yasser Al-Dossari | `ar.yasseraldossari` |
| Al-Husary | `ar.husary` |
| Abdul Basit | `ar.abdulbasitmurattal` |
| Al-Minshawi | `ar.minshawi` |

## License

This is a personal reference tool built for educational purposes. Recitation audio is served by public CDNs (Islamic Network, EveryAyah). Supplication audio is sourced from Hisnul Muslim and Dr. Saleh As-Saleh. Respect the rights of the original reciters and content creators.
