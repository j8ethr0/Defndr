//
// MLModelHealthMonitor.swift
// Dro1d Labs — Defndr (Reference)
// Purpose: On-device model health telemetry (latency histograms, confidence drift detection, input anomaly counters).
// Designed for privacy-first on-device monitoring and optional aggregated telemetry (opt-in).
//

import Foundation
import os.log

public actor MLModelHealthMonitor {

	public struct Snapshot: Codable {
		public var timestamp: Date
		public var modelLatencyMs: Double
		public var confidenceMean: Double
		public var confidenceStd: Double
		public var anomalies: [String: Int]
		public var latencyP95: Double
	}

	// Rolling buffers
	private var latencies: [Double] = []
	private var confidences: [Double] = []
	private var anomalyCounters: [String: Int] = [:]

	private let maxSamples = 1000
	private let logger = Logger(subsystem: "com.sms-defndr.ml", category: "health")

	// Configuration (exposed for tests / diagnostics)
	public var anomalyThreshold: Double = 0.25     // e.g., sudden spike in low-confidence predictions
	public var driftWindow: Int = 300

	public init() {}

	public func recordPrediction(latencyMs: Double, confidence: Double) {
		latencies.append(latencyMs)
		confidences.append(confidence)
		if latencies.count > maxSamples { latencies.removeFirst(latencies.count - maxSamples) }
		if confidences.count > maxSamples { confidences.removeFirst(confidences.count - maxSamples) }

		// Quick anomaly heuristics
		if confidence < 0.1 { incrementAnomaly("veryLowConfidence") }
		if confidence < 0.4 { incrementAnomaly("lowConfidence") }
		if latencyMs > 200.0 { incrementAnomaly("highLatency") }

		#if DEBUG
		logger.log("ML health snapshot — meanLatency: \(mean(latencies))ms, meanConfidence: \(mean(confidences))")
		#endif
	}

	public func snapshot() -> Snapshot {
		Snapshot(
			timestamp: Date(),
			modelLatencyMs: mean(latencies),
			confidenceMean: mean(confidences),
			confidenceStd: stddev(confidences),
			anomalies: anomalyCounters,
			latencyP95: percentile(latencies, 0.95),
		)
	}

	public func clear() {
		latencies.removeAll()
		confidences.removeAll()
		anomalyCounters.removeAll()
	}

	// Simple local check for drift — compares recent window mean to historical mean
	public func detectDrift() -> Bool {
		guard confidences.count >= driftWindow * 2 else { return false }
		let recent = Array(confidences.suffix(driftWindow))
		let historic = Array(confidences.prefix(confidences.count - driftWindow))
		let recentMean = mean(recent)
		let historicMean = mean(historic)
		let delta = abs(recentMean - historicMean)
		return delta >= anomalyThreshold
	}

	// MARK: - Private helpers

	private func percentile(_ values: [Double], _ p: Double) -> Double {
		guard !values.isEmpty else { return 0.0 }
		let sorted = values.sorted()
		let index = Int(Double(sorted.count) * p)
		return sorted[min(index, sorted.count - 1)]
	}
	
	private func incrementAnomaly(_ key: String) {
		anomalyCounters[key, default: 0] += 1
	}

	private func mean(_ xs: [Double]) -> Double {
		guard !xs.isEmpty else { return 0.0 }
		return xs.reduce(0, +) / Double(xs.count)
	}

	private func stddev(_ xs: [Double]) -> Double {
		guard xs.count > 1 else { return 0.0 }
		let m = mean(xs)
		let variance = xs.reduce(0) { $0 + pow($1 - m, 2) } / Double(xs.count - 1)
		return sqrt(variance)
	}
}