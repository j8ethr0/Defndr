![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![iOS](https://img.shields.io/badge/iOS-18+-lightgrey.svg)
![Architecture](https://img.shields.io/badge/On--Device-ML-blue.svg)
![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local-green.svg)
![Security](https://img.shields.io/badge/Security-Hardened-black.svg)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen.svg)

# Defndr

**Private. Local. Intelligent SMS Spam Defense.**  
Built by **Dro1d Labs — defndr.org**

Defndr is a modern, privacy-first SMS spam filter for iOS. It processes messages **entirely on-device**, never sending data to servers, clouds, analytics platforms, or ads. Defndr is engineered for people who care about security, minimalism, and real protection—without compromising performance.

---

## 📢 App Store Availability

**Defndr is currently live on the iOS App Store.**

A previous pause in repository updates was taken to evaluate iOS 18’s new filtering framework limitations and to protect Defndr’s **proprietary model internals**. The public repo is now being updated again with new architectural modules, tooling, and documentation that reflect the ongoing evolution of the app—without exposing sensitive IP.

For updates, announcements, and research:

- **Official site:** https://defndr.org  
- **Dro1d Labs Research:** https://dro1d.org/defndr

---

## About This Repository

This repository provides a **technical reference** for Defndr’s privacy-first on-device architecture. While it does not include the full proprietary filtering pipeline, model tuning engine, or adaptive language framework, it demonstrates:

- Deterministic message sanitization and preprocessing  
- How hybrid scoring blends ML confidence with heuristics  
- On-device model health monitoring without telemetry  
- High-performance design for iOS 17/18+  

The code is designed to support **transparency and understanding**, while maintaining the safety of the official Defndr IP.

---

## 🔬 Architect & Research Modules (Dro1d Labs)

These modules illustrate Defndr’s engineering approach and are written as first-class reference implementations:

### `Sources/MessagePreprocessingPipeline.swift`
Deterministic text normalization and token-pathway construction with lightweight pseudo-embeddings and on-device caching.

### `Sources/HeuristicSignalScoring.swift`
A JSON-configurable hybrid scoring engine that demonstrates how ML outputs, heuristics, and sender-level signals can be combined into a unified spam detection score.

### `Sources/MLModelHealthMonitor.swift`
A localized diagnostic layer providing:
- Latency histograms  
- Confidence drift detection  
- Anomaly counters  
- Local-only observability buffers  

This module is fully offline and respects Defndr’s strict privacy principles.

---

## ⚠️ Important Notice

The included ML model (`SpamClassifier.mlmodel`) and `vocabulary.json` are the **intellectual property of the Defndr team** and are provided for **educational and reference purposes only**.

You are **not permitted** to:
- copy  
- modify  
- reuse  
- distribute  
- integrate  
- repackage  

any model, vocabulary, or source code from this repository into your own applications or commercial products without explicit written permission.

This project exists to support transparency and academic insight—not redistribution.

---

## 🔒 Why Defndr Exists

Modern SMS spam filters rely on servers, analytics pipelines, profiling, or data harvesting.  
Defndr was built to prove something different:

**That world-class SMS protection can be done entirely on-device, privately, and without selling your data.**

Defndr’s mission:
- To eliminate hidden trackers, cloud processing, and profiling.
- To provide machine-learning filters that never leave your phone.
- To stay lightweight, fast, and brutally minimal.
- To build security tools normal people can trust.

Defndr exists because privacy should not be a premium feature — it should be the standard.

---

## Screenshots

(Add your own app screenshots here)

![Defndr Clean Inbox](screenshots/inbox.png)
![Defndr Blocked Spam](screenshots/blocked.png)
![Defndr Settings](screenshots/settings.png)

## Pipeline Overview

flowchart LR
	A[Raw SMS] --> B[MessagePreprocessingPipeline]
	B --> C[Heuristics + ML Vote]
	C --> D[HeuristicSignalScoring]
	D --> E[Block / Allow Decision]
	
License
	Educational and reference purposes only. No commercial use, modification, or redistribution permitted without explicit written permission from Dro1d Labs.
	
🧭 Stay Updated
	For updates, roadmap details, research posts, and announcements:
	https://defndr.org