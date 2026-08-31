<p align="center"><img src="icon.svg" width="120" height="120" alt="Sabeel icon"></p>

<h1 align="center">سبيل Sabeel — Your Path Into Islam</h1>

<p align="center">A private, offline reference app for new Muslims — essentials, prayer, Qibla, wudhu, salah, fiqh, Ramadan, Hajj, duas, Qur'an reader, and more.</p>

<p align="center"><strong>This project was created through a collaboration between AI and me guiding it. Every feature, line of code, and content decision was shaped by that partnership.</strong></p>

---

## What's Inside

Sabeel is a single HTML file that covers almost everything a new Muslim needs to learn and practice their deen. No accounts, no tracking, no ads. Just open it and use it.

**Core Features**
- **Islamic Essentials** — Beliefs, pillars, and articles of faith explained in plain English with Arabic text
- **Prayer Times** — Calculate from your location or set manually, with 11 calculation methods
- **Qibla Finder** — Compass-based direction from anywhere in the world
- **Wudhu &amp; Salah Practice** — Step-by-step guided practice with audio recitation and checklists
- **Fiqh Overview** — The four Sunni schools: what they agree on, where they differ
- **Ramadan &amp; Hajj** — Obligations, step-by-step guides, and common questions answered
- **Duas Collection** — 70+ supplications from Hisnul Muslim with Arabic, transliteration, English, and audio
- **Qur'an Reader** — Browse any verse with 7 real reciters, play/pause, and speed control
- **Knowledge Check** — Quiz yourself across all topics with scoring and streaks

**Worship Tools**
- **Dhikr Counter** — Tap to count, 6 preset dhikr, target system, session history
- **Missed Prayers (Qada)** — Track what you owe and log what you make up
- **Pray Along** — Real-time salah guide that walks you through each position with audio
- **Offline Content Packs** — Download audio bundles for use without internet

**Learning**
- **Arabic Reading Course** — Alphabet, letter connections, common words, and short surahs
- **Hifz Tracker** — Memorization grid for all 114 surahs with spaced-repetition testing
- **Islamic Calendar** — Hijri dates with Islamic events and observances

**Guidance**
- **Tawheed** — The oneness of God explained clearly
- **Onboarding Roadmap** — A 10-step learning path for new Muslims

## Getting Started

No server needed. Just open the file.

```bash
git clone https://github.com/BMQ-10/Sabeel.git
open Sabeel.html
```

Works in any modern browser on phone, tablet, or desktop. You can also install it as a PWA (Progressive Web App) for offline access.

## File Structure

```
.
├── Sabeel.html    # The entire app (HTML + CSS + JS, ~9200 lines, single file)
├── sw.js          # Service worker for offline caching
├── icon.svg       # App icon (lantern with glowing flame)
├── README.md      # This file
└── .gitignore
```

## Tech Stack

- **Pure HTML/CSS/JS** — No frameworks, no build tools, no dependencies. Just one file.
- **Quran.com API** — Verse text, reciter audio, and word-level timing segments
- **Hisnul Muslim** — Human-recorded supplication audio
- **Web APIs** — Geolocation, Speech Synthesis, Audio, Clipboard
- **IndexedDB** — Offline content pack storage
- **Service Worker** — Caches the app shell for true offline use

## Reciters

7 reciters with real recordings from the Islamic Network CDN:

| Reciter | ID |
|---|---|
| Maher Al-Muaiqly (default) | `ar.mahermuaiqly` |
| Mishary Alafasy | `ar.alafasy` |
| Saud Al-Shuraim | `ar.saoodshuraym` |
| Yasser Al-Dossari | `ar.yasseraldossari` |
| Al-Husary | `ar.husary` |
| Abdul Basit | `ar.abdulbasitmurattal` |
| Al-Minshawi | `ar.minshawi` |

## Languages

The interface supports 6 languages: English, Spanish, French, Turkish, Urdu (right-to-left), and Malay. Select from the dropdown in the sidebar.

## License

This is a personal reference tool built for educational purposes. Recitation audio is served by public CDNs (Islamic Network, EveryAyah). Supplication audio is sourced from Hisnul Muslim and Dr. Saleh As-Saleh. Respect the rights of the original reciters and content creators.
