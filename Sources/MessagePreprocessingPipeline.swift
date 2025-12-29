//
// MessagePreprocessingPipeline.swift
// Dro1d Labs — Defndr (Reference)
// Target: iOS 26+
// Purpose: Ultra-robust, privacy-first preprocessing pipeline for on-device inference.
// NOTE: This file is intentionally implementation-focused and safe — it contains no training logic.
//

import Foundation
import CryptoKit
import NaturalLanguage

public actor PreprocessingCache {
	private var embeddings: [String: [Float]] = [:]
	func getEmbedding(for key: String) -> [Float]? { embeddings[key] }
	func setEmbedding(_ e: [Float], for key: String) { embeddings[key] = e }
	func clear() { embeddings.removeAll() }
}

/// High level pipeline that prepares raw SMS text for model / heuristics.
/// - tokenization
/// - normalization (unicode, punctuation fold, diacritics removal)
/// - lightweight feature extraction
/// - safe, deterministic hashing for caching (no secrets)
public struct MessagePreprocessingPipeline {
	public enum Mode {
		case minimal      // only basic cleaning + tokens
		case standard     // tokens + normalization + basic features
		case verbose      // includes token embeddings (placeholder) + diagnostics
	}

	private let mode: Mode
	private let languageRecognizer = NLLanguageRecognizer()
	private let cache = PreprocessingCache()
	private let punctuationSet: CharacterSet = {
		var s = CharacterSet.punctuationCharacters
		s.formUnion(.symbols)
		return s
	}()

	public init(mode: Mode = .standard) {
		self.mode = mode
	}

	public struct ProcessedMessage: Codable {
		public let idHash: String         // deterministic id for caching (no PII)
		public let normalizedText: String
		public let tokens: [String]
		public let language: String?
		public let length: Int
		public let tokenCount: Int
		public let shallowFeatures: [String: Double] // punctuation rate, caps ratio, urlCount, currencyCount
		public var embeddingFingerprint: String?     // placeholder fingerprint when embeddings exist
	}

	// Deterministic, privacy-preserving fingerprint (SHA256 of normalized text)
	public static func fingerprint(for text: String) -> String {
		let normalized = text.precomposedStringWithCompatibilityMapping.trimmingCharacters(in: .whitespacesAndNewlines)
		let data = Data(normalized.utf8)
		let digest = SHA256.hash(data: data)
		return digest.compactMap { String(format: "%02x", $0) }.joined()
	}

	public func extractURLs(from text: String) -> [String] {
		guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
		let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
		return matches.compactMap { $0.url?.absoluteString }
	}
	
	/// Main entry - returns a processed message suitable for feature vector building or heuristics
	public func process(_ rawText: String) async -> ProcessedMessage {
		let normalized = await normalize(rawText)
		let tokens = await tokenize(normalized)
		let language = detectLanguage(from: normalized)
		let shallow = await shallowFeatures(from: rawText, tokens: tokens)
		var fingerprint = Self.fingerprint(for: normalized)
		var embeddingFingerprint: String? = nil
		let shortMsgWithUrl = (Double(original.count) < 60 && urlCount >= 1) ? 1.0 : 0.0

		if mode == .verbose {
			// Placeholder embedding generation (no external network, safe deterministic pseudo-embedding)
			if let cached = await cache.getEmbedding(for: fingerprint) {
				embeddingFingerprint = "cached:\(cached.count)"
			} else {
				let embedding = Self.pseudoEmbedding(from: tokens)
				await cache.setEmbedding(embedding, for: fingerprint)
				embeddingFingerprint = "gen:\(embedding.count)"
			}
		}

		return ProcessedMessage(
			idHash: fingerprint,
			normalizedText: normalized,
			tokens: tokens,
			language: language?.rawValue,
			length: normalized.count,
			tokenCount: tokens.count,
			shallowFeatures: shallow,
			"shortMsgWithUrl": shortMsgWithUrl,
			embeddingFingerprint: embeddingFingerprint
		)
	}

	// MARK: - Private helpers

	private func normalize(_ text: String) async -> String {
		// Unicode normalisation (NFKC), remove control chars, collapse whitespace, remove problematic invisible chars
		var s = text.precomposedStringWithCompatibilityMapping
		s = s.replacingOccurrences(of: "\u{00A0}", with: " ") // non-breaking spaces
		s = s.replacingOccurrences(of: "\\p{C}", with: "", options: .regularExpression) // control chars
		s = s.trimmingCharacters(in: .whitespacesAndNewlines)
		// fold punctuation to ASCII where useful, remove repeated whitespace
		s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
		return s
	}

	private func tokenize(_ normalized: String) async -> [String] {
		// Use a conservative tokenization strategy: split on whitespace + punctuation, but keep short tokens
		let rawTokens = normalized.split { $0.isWhitespace || punctuationSet.contains($0.unicodeScalars.first!) }
			.map { String($0) }
			.filter { !$0.isEmpty }

		// basic cleanup: strip surrounding punctuation, trim to max token length for stability
		let tokens = rawTokens.map {
			$0.trimmingCharacters(in: CharacterSet.punctuationCharacters).lowercased()
		}.map { token -> String in
			if token.count > 50 { return String(token.prefix(50)) } else { return token }
		}

		return tokens
	}

	private func detectLanguage(from normalized: String) -> NLLanguage? {
		languageRecognizer.processString(normalized)
		let lang = languageRecognizer.dominantLanguage
		languageRecognizer.reset()
		return lang
	}

	private func shallowFeatures(from original: String, tokens: [String]) async -> [String: Double] {
		// punctuation rate, allcaps ratio, url count, currency symbol count, numeric density
		let punctuationCount = Double(original.filter { CharacterSet.punctuationCharacters.contains($0.unicodeScalars.first!) }.count)
		let length = Double(max(1, original.count))
		let punctuationRate = punctuationCount / length

		let alphaTokens = tokens.filter { $0.rangeOfCharacter(from: .letters) != nil }
		let capsCount = Double(alphaTokens.filter { $0.uppercased() == $0 && $0.count >= 3 }.count)
		let capsRatio = alphaTokens.isEmpty ? 0.0 : capsCount / Double(alphaTokens.count)

		let urlCount = Double(original.matches(regex: #"(https?://|www\.)[^\s]+"#).count)
		let currencySymbols = CharacterSet(charactersIn: "$€£¥₹₱₽₩฿").union(.symbols)
		let currencyCount = Double(original.unicodeScalars.filter { currencySymbols.contains($0) }.count)

		let numericDensity = Double(original.filter { $0.isNumber }.count) / length

		return [
			"punctuationRate": punctuationRate,
			"capsRatio": capsRatio,
			"urlCount": urlCount,
			"currencyCount": currencyCount,
			"numericDensity": numericDensity
		]
	}

	/// Deterministic pseudo-embedding for offline fingerprinting (safe placeholder)
	private static func pseudoEmbedding(from tokens: [String]) -> [Float] {
		// Not a real embedding. Produces deterministic floats for cache/demo purposes.
		var out: [Float] = []
		var state: UInt64 = 0x9e3779b97f4a7c15
		for t in tokens {
			var h: UInt64 = 1469598103934665603
			for b in t.utf8 {
				h ^= UInt64(b)
				h = (h &* 1099511628211) &+ 0x9e3779b97f4a7c15
			}
			state = state &+ h
			out.append(Float((state & 0xffff) % 1000) / 1000.0)
			if out.count >= 64 { break }
		}
		while out.count < 64 { out.append(0) }
		return out
	}
}

// MARK: - String helpers
fileprivate extension String {
	func matches(regex: String) -> [NSTextCheckingResult] {
		guard let re = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) else { return [] }
		return re.matches(in: self, range: NSRange(startIndex..., in: self))
	}
}