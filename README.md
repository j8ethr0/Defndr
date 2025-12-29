![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![iOS](https://img.shields.io/badge/iOS-18+-lightgrey.svg)
![Architecture](https://img.shields.io/badge/On--Device-ML-blue.svg)
![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local-green.svg)
![Security](https://img.shields.io/badge/Security-Hardened-black.svg)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen.svg)

# Defndr

**Private, local SMS spam filtering** — built by **Dro1d Labs**.

Defndr processes messages **entirely on-device**, providing high-accuracy SMS spam detection without sending any data off the device.  

---

## App Store

Defndr is live on the iOS App Store.

Official site: https://defndr.org  
Research: https://dro1d.org/defndr  

---

## Repository Purpose

This repository provides **reference implementations** for:

- Deterministic SMS preprocessing  
- Hybrid spam scoring combining heuristics and ML  
- On-device monitoring of model performance  
- High-performance architecture for iOS 17/18+  

It **does not include the proprietary filtering model or pipeline**.

---

## Modules

### `Sources/MessagePreprocessingPipeline.swift`
Tokenization, normalization, and deterministic preprocessing of SMS text.

### `Sources/HeuristicSignalScoring.swift`
Combines heuristics and ML scoring for spam classification.

### `Sources/MLModelHealthMonitor.swift`
Monitors model performance and drift **entirely on-device**.

---

## License / Restrictions

- All code, models, and data are **Dro1d Labs intellectual property**.  
- No copying, redistribution, or commercial use without explicit written permission.

---

## Pipeline Overview

flowchart LR
	A[Raw SMS] --> B[MessagePreprocessingPipeline]
	B --> C[Heuristics + ML Vote]
	C --> D[HeuristicSignalScoring]
	D --> E[Block / Allow Decision]

License: Educational and reference purposes only. No commercial use, modification, or redistribution permitted without explicit written permission from Dro1d Labs.

🧭 Stay Updated: https://defndr.org
