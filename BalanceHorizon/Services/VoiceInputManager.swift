// VoiceInputManager.swift — Balance Horizon
// Hands-free voice input for transaction entry.
// Say "fifty dollars groceries" and it parses the amount and category.

import SwiftUI
import Speech
import AVFoundation
import Observation

@Observable
class VoiceInputManager {
    var isListening: Bool = false
    var transcript: String = ""
    var parsedAmount: Double? = nil
    var parsedCategory: String? = nil
    var errorMessage: String? = nil

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    // MARK: - Permission

    /// Requests speech recognition authorization. Returns true if granted.
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Listening

    /// Starts live speech recognition via the device microphone.
    func startListening() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available on this device."
            return
        }

        // Reset state
        errorMessage = nil
        transcript = ""
        parsedAmount = nil
        parsedCategory = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            errorMessage = "Unable to create recognition request."
            return
        }
        recognitionRequest.shouldReportPartialResults = true

        audioEngine = AVAudioEngine()
        guard let audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            if let result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.tearDownAudio()
                    self.isListening = false
                    if error != nil && self.transcript.isEmpty {
                        self.errorMessage = "Could not recognize speech. Please try again."
                    } else {
                        self.parseTranscript()
                    }
                }
            }
        }

        do {
            try audioEngine.start()
            isListening = true
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
            tearDownAudio()
        }
    }

    /// Stops listening and triggers transcript parsing.
    func stopListening() {
        recognitionRequest?.endAudio()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        isListening = false
        parseTranscript()
    }

    private func tearDownAudio() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
    }

    // MARK: - Transcript Parsing

    /// Pure string parsing — extracts amount and category from the transcript.
    func parseTranscript() {
        let text = transcript.lowercased()
        parsedAmount = extractAmount(from: text)
        parsedCategory = extractCategory(from: text)
    }

    // MARK: Amount Extraction

    private func extractAmount(from text: String) -> Double? {
        // Try numeric patterns first: "$50", "50.00", "$1,234.56"
        if let numeric = extractNumericAmount(from: text) {
            return numeric
        }
        // Try spoken word numbers: "fifty dollars", "twenty five bucks", "ten fifty"
        if let spoken = extractSpokenAmount(from: text) {
            return spoken
        }
        return nil
    }

    private func extractNumericAmount(from text: String) -> Double? {
        let pattern = #"\$?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        let cleaned = String(text[range]).replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    private func extractSpokenAmount(from text: String) -> Double? {
        let words = text
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Build number tokens from word sequence
        var numberParts: [Double] = []
        var i = 0
        while i < words.count {
            if let val = wordToNumber(words[i]) {
                // Check for "hundred" following
                if i + 1 < words.count, words[i + 1] == "hundred" {
                    var compound = val * 100
                    i += 2
                    // Check for tens/units after hundred
                    if i < words.count, let extra = wordToNumber(words[i]) {
                        // e.g. "two hundred fifty"
                        if i + 1 < words.count, let units = wordToNumber(words[i + 1]),
                           extra >= 20, units < 10 {
                            compound += extra + units
                            i += 2
                        } else {
                            compound += extra
                            i += 1
                        }
                    }
                    numberParts.append(compound)
                } else if val >= 20, i + 1 < words.count, let units = wordToNumber(words[i + 1]), units < 10 {
                    // "twenty five" = 25
                    numberParts.append(val + units)
                    i += 2
                } else {
                    numberParts.append(val)
                    i += 1
                }
            } else {
                i += 1
            }
        }

        guard !numberParts.isEmpty else { return nil }

        // Handle "ten fifty" pattern => $10.50 (two separate number groups, second < 100)
        if numberParts.count == 2, numberParts[1] < 100 {
            let whole = numberParts[0]
            let cents = numberParts[1]
            return whole + cents / 100.0
        }

        // Otherwise return the first (or largest) parsed number
        return numberParts.first
    }

    private static let wordNumbers: [String: Double] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
        "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
        "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
        "eighty": 80, "ninety": 90, "hundred": 100
    ]

    private func wordToNumber(_ word: String) -> Double? {
        Self.wordNumbers[word]
    }

    // MARK: Category Extraction

    private static let categoryKeywords: [(keywords: [String], category: String)] = [
        (["grocery", "groceries"], "Groceries"),
        (["food", "dinner", "lunch", "restaurant", "eat", "eating", "dining"], "Dining"),
        (["coffee", "starbucks", "cafe"], "Dining"),
        (["gas", "uber", "lyft", "taxi", "bus", "train", "transport", "transportation"], "Transport"),
        (["rent", "mortgage"], "Rent"),
        (["electric", "electricity", "water", "internet", "phone", "utility", "utilities"], "Utilities"),
        (["amazon", "shop", "shopping", "buy", "bought", "store", "purchase"], "Shopping"),
    ]

    private func extractCategory(from text: String) -> String {
        let words = Set(
            text.components(separatedBy: .alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )
        for entry in Self.categoryKeywords {
            for keyword in entry.keywords {
                if words.contains(keyword) {
                    return entry.category
                }
            }
        }
        return "General"
    }
}

// MARK: - Voice Input Button View

struct VoiceInputButton: View {
    @Bindable var manager: VoiceInputManager
    var onConfirm: (Double, String) -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var barHeights: [CGFloat] = [0.3, 0.5, 0.3]

    var body: some View {
        VStack(spacing: 12) {
            // Parsed result display
            if !manager.isListening, manager.parsedAmount != nil {
                parsedResultView
                    .transition(.opacity.combined(with: .scale))
            }

            // Live transcript
            if manager.isListening, !manager.transcript.isEmpty {
                Text(manager.transcript)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineLimit(3)
                    .transition(.opacity)
            }

            // Waveform indicator when listening
            if manager.isListening {
                waveformIndicator
                    .frame(height: 24)
                    .transition(.opacity)
            }

            // Main mic button
            ZStack {
                // Pulsing glow when listening
                if manager.isListening {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 72, height: 72)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                }

                Circle()
                    .fill(manager.isListening ? Color.red : Color.accentColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: (manager.isListening ? Color.red : Color.accentColor).opacity(0.4),
                            radius: 8, y: 2)

                Image(systemName: manager.isListening ? "stop.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                if manager.isListening {
                    manager.stopListening()
                } else {
                    Task {
                        let granted = await manager.requestPermission()
                        if granted {
                            manager.startListening()
                            pulseScale = 1.3
                            startWaveformAnimation()
                        } else {
                            manager.errorMessage = "Microphone permission is required."
                        }
                    }
                }
            }

            // Error display
            if let error = manager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: manager.isListening)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: manager.parsedAmount)
    }

    // MARK: - Parsed Result

    @ViewBuilder
    private var parsedResultView: some View {
        VStack(spacing: 8) {
            if let amount = manager.parsedAmount, let category = manager.parsedCategory {
                HStack {
                    Text("Amount: \(formattedAmount(amount))")
                        .font(.subheadline.weight(.semibold))
                    Text("|")
                        .foregroundStyle(.secondary)
                    Text("Category: \(category)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.primary)

                HStack(spacing: 16) {
                    Button {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        onConfirm(amount, category)
                    } label: {
                        Label("Confirm", systemImage: "checkmark")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green, in: Capsule())
                            .foregroundStyle(.white)
                    }

                    Button {
                        manager.parsedAmount = nil
                        manager.parsedCategory = nil
                        manager.transcript = ""
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.2), in: Capsule())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Waveform

    @ViewBuilder
    private var waveformIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 4, height: 24 * barHeights[index])
            }
        }
    }

    private func startWaveformAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if !manager.isListening {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                barHeights = (0..<3).map { _ in CGFloat.random(in: 0.2...1.0) }
            }
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}
