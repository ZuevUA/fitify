//
//  VoiceInputService.swift
//  Fitify
//

import Foundation
import Speech
import AVFoundation

@Observable
final class VoiceInputService {
    private let recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var transcript = ""
    var isRecording = false
    var isAuthorized = false
    var errorMessage: String?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "uk-UA"))
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        await MainActor.run {
            switch status {
            case .authorized:
                isAuthorized = true
            case .denied:
                errorMessage = "Доступ до розпізнавання мовлення відхилено"
                isAuthorized = false
            case .restricted:
                errorMessage = "Розпізнавання мовлення недоступне на цьому пристрої"
                isAuthorized = false
            case .notDetermined:
                errorMessage = "Статус авторизації не визначено"
                isAuthorized = false
            @unknown default:
                isAuthorized = false
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            errorMessage = "Розпізнавання мовлення недоступне"
            return
        }

        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Не вдалося створити запит на розпізнавання"
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.transcript = result.bestTranscription.formattedString
            }

            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        transcript = ""
        isRecording = true
        errorMessage = nil
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            do {
                try startRecording()
            } catch {
                errorMessage = "Помилка запису: \(error.localizedDescription)"
            }
        }
    }
}
