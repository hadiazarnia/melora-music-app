import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var importChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Configure audio session - use simpler options to avoid errors
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Don't crash, just log
            print("Melora: Audio session setup note: \(error.localizedDescription)")
        }
        
        // Setup import channel
        if let controller = window?.rootViewController as? FlutterViewController {
            importChannel = FlutterMethodChannel(
                name: "melora/import",
                binaryMessenger: controller.binaryMessenger
            )
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle "Open In" from Files app, Safari, Chrome, etc.
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        handleIncomingFile(url: url)
        return true
    }
    
    private func handleIncomingFile(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let importDir = documentsDir.appendingPathComponent("imported_audio", isDirectory: true)
        
        // Create import directory
        try? fileManager.createDirectory(at: importDir, withIntermediateDirectories: true)
        
        let destinationURL = importDir.appendingPathComponent(url.lastPathComponent)
        
        // Remove existing file with same name
        try? fileManager.removeItem(at: destinationURL)
        
        do {
            try fileManager.copyItem(at: url, to: destinationURL)
            importChannel?.invokeMethod("importAudioFile", arguments: destinationURL.path)
            print("Melora: Imported: \(destinationURL.lastPathComponent)")
        } catch {
            // Fallback: try sending original URL
            importChannel?.invokeMethod("importAudioFile", arguments: url.path)
            print("Melora: Import fallback: \(url.lastPathComponent)")
        }
    }
}