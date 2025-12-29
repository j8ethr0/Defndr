//
// HeuristicSignalScoring.swift
// Dro1d Labs — Defndr (Reference)
// Purpose: Combine multiple lightweight signals (heuristics) with configurable weights into a single risk score.
// This file demonstrates advanced scoring logic, per-sender tuning, and config-driven thresholds.
//

import Foundation

public struct HeuristicSignalScoring {

	public struct Signal: Codable {
		public let name: String
		public let weight: Double           // positive weights increase risk
		public let description: String?
		public let active: Bool
	}

	public struct ScoringConfig: Codable {
		public var globalThreshold: Double
		public var minConfidence: Double
		public var signals: [Signal]
		public var perSenderOverrides: [String: Double] // sender -> threshold delta
	}

	public struct ScoreResult {
		public let rawScore: Double
		public let normalizedScore: Double // 0..1
		public let triggered: [String]
		public let reason: String
	}

	private var config: ScoringConfig
	private let queue = DispatchQueue(label: "com.dro1d.scoring", attributes: .concurrent)

	public init(config: ScoringConfig? = nil) {
		if let c = config {
			self.config = c
		} else {
			// sensible defaults for a production-looking project
			self.config = ScoringConfig(
				globalThreshold: 0.65,
				minConfidence: 0.3,
				signals: [
					Signal(name: "urlPresence", weight: 0.25, description: "Non-whitelisted URL detected", active: true),
					Signal(name: "punctuationBurst", weight: 0.10, description: "Excess punctuation detected", active: true),
					Signal(name: "numericDensity", weight: 0.05, description: "High numeric density", active: true),
					Signal(name: "shortMsgWithUrl", weight: 0.20, description: "Short message containing URL", active: true),
					Signal(name: "capsBurst", weight: 0.08, description: "High ALL CAPS usage", active: true),
					Signal(name: "currencyBurst", weight: 0.06, description: "Many currency symbols", active: true),
					Signal(name: "mlSpamVote", weight: 0.30, description: "ML model predicted spam with high confidence", active: true)
				],
				perSenderOverrides: [:]
			)
		}
	}

	/// Load config from JSON (safe, optional)
	public mutating func loadConfig(from data: Data) throws {
		let decoder = JSONDecoder()
		let parsed = try decoder.decode(ScoringConfig.self, from: data)
		queue.async(flags: .barrier) { [weak self] in
			self?.config = parsed
		}
	}

	/// Evaluate numeric signals and return a ScoreResult.
	/// - Parameters:
	///   - shallowFeatures: from the preprocessing pipeline (punctuationRate, capsRatio, urlCount, currencyCount)
	///   - mlVote: optional model probability for "spam" (0..1)
	///   - sender: optional sender string for per-sender overrides
	public func evaluate(shallowFeatures: [String: Double], mlVote: Double?, sender: String?) -> ScoreResult {
		var rawScore = 0.0
		var triggered: [String] = []

		// thread-safely read config snapshot
		let cfg = queue.sync { config }

		for s in cfg.signals where s.active {
			switch s.name {
			case "urlPresence":
				let urlCount = shallowFeatures["urlCount"] ?? 0
				if urlCount >= 1 {
					rawScore += s.weight * min(1.0, urlCount)
					triggered.append(s.name)
				}
			case "punctuationBurst":
				let pr = shallowFeatures["punctuationRate"] ?? 0
				if pr > 0.06 {
					rawScore += s.weight * (pr * 10.0) // scaled
					triggered.append(s.name)
				}
			case "capsBurst":
				let cr = shallowFeatures["capsRatio"] ?? 0
				if cr > 0.25 {
					rawScore += s.weight * (cr * 2.0)
					triggered.append(s.name)
				}
			case "currencyBurst":
				let cc = shallowFeatures["currencyCount"] ?? 0
				if cc >= 1 {
					rawScore += s.weight * min(1.0, cc)
					triggered.append(s.name)
				}
			case "numericDensity":
					let nd = shallowFeatures["numericDensity"] ?? 0
					if nd > 0.3 {
						rawScore += s.weight * nd
						triggered.append(s.name)
					}
			case "shortMsgWithUrl":
					if (shallowFeatures["shortMsgWithUrl"] ?? 0) > 0 {
						rawScore += s.weight
						triggered.append(s.name)
					}
			case "mlSpamVote":
				if let ml = mlVote {
					// ML vote contributes more when confident
					rawScore += s.weight * ml
					if ml >= 0.5 { triggered.append(s.name) }
				}
			default:
				continue
			}
		}

		// per-sender threshold delta (for whitelisting business senders etc.)
		let senderDelta = sender.flatMap { cfg.perSenderOverrides[$0] } ?? 0.0
		let effectiveThreshold = max(0.0, min(1.0, cfg.globalThreshold + senderDelta))

		// normalize rawScore (best-effort: clamp to 0..1)
		let normalized = 1 / (1 + exp(-12 * (rawScore - 0.5))) // steeper curve

		let reason = normalized >= effectiveThreshold ? "Score >= threshold (\(String(format: "%.2f", normalized)) >= \(String(format: "%.2f", effectiveThreshold)))" : "Score below threshold (\(String(format: "%.2f", normalized)) < \(String(format: "%.2f", effectiveThreshold)))"

		return ScoreResult(rawScore: rawScore, normalizedScore: normalized, triggered: triggered, reason: reason)
	}

	// Expose a JSON configuration example for maintainers
	public static func exampleConfigJSON() -> String {
		let example = ScoringConfig(
			globalThreshold: 0.65,
			minConfidence: 0.3,
			signals: [
				Signal(name: "urlPresence", weight: 0.25, description: "Non-whitelisted URL detected", active: true),
				Signal(name: "punctuationBurst", weight: 0.10, description: "Excess punctuation detected", active: true),
				Signal(name: "mlSpamVote", weight: 0.30, description: "ML model predicted spam with high confidence", active: true)
			],
			perSenderOverrides: ["TrustedBrand": -0.2]
		)
		let enc = JSONEncoder()
		enc.outputFormatting = [.prettyPrinted, .sortedKeys]
		return (try? String(data: enc.encode(example), encoding: .utf8)) ?? "{}"
	}
}