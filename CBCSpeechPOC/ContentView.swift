//
//  ContentView.swift
//  CBCSpeechPOC
//
//  Created by Phil Chan on 4/12/23.
//

import SwiftUI

import SwiftUI
import Speech

struct ContentView: View {
    @State private var transcription = ""
    @State private var isRecording = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var body: some View {
        VStack {
            Text(transcription)
                .padding()
            Button(action: {
                if audioEngine.isRunning {
                    audioEngine.stop()
                    recognitionRequest?.endAudio()
                    isRecording = false
                } else {
                    startRecording()
                    isRecording = true
                }
            }) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(100)
                    .foregroundColor(.blue)
            }
            .disabled(!speechRecognizer!.isAvailable)
        }
    }

    func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                transcription = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)

                recognitionRequest.endAudio()
                recognitionTask = nil

                isRecording = false
            }
        }

        let inputNode = audioEngine.inputNode

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        transcription = "Say something, I'm listening!"
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
