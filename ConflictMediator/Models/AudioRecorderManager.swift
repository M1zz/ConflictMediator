import Foundation
import AVFoundation

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var permissionGranted = false
    @Published var recordingURL: URL?

    private var audioRecorder: AVAudioRecorder?
    private let recordingsDirectory: URL

    override init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("Recordings", isDirectory: true)

        super.init()

        try? FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() -> Bool {
        guard permissionGranted else { return false }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
            return false
        }

        let fileName = generateFileName()
        recordingURL = recordingsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.record()
            isRecording = true
            return true
        } catch {
            print("녹음 시작 실패: \(error)")
            return false
        }
    }

    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else { return nil }

        recorder.stop()
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false)

        return recordingURL
    }

    private func generateFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        return "\(dateString)_대화녹음.m4a"
    }

    func getRecordings() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: recordingsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            return files.filter { $0.pathExtension == "m4a" }
                .sorted { (url1, url2) -> Bool in
                    let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
                    let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
                    return date1 ?? Date.distantPast > date2 ?? Date.distantPast
                }
        } catch {
            print("녹음 파일 목록 가져오기 실패: \(error)")
            return []
        }
    }
}
