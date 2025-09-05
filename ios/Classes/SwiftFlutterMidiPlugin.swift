import Flutter
import UIKit
import AVFoundation

public class SwiftFlutterMidiPlugin: NSObject, FlutterPlugin {
  var message = "Please Send Message"
  var _arguments = [String: Any]()
  var au: AudioUnitMIDISynth!

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_midi", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMidiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "prepare_midi":
        let map = call.arguments as? Dictionary<String, String>
        let data = map?["path"]
        let url = URL(fileURLWithPath: data!)
        print("prepare midi")
        do {
          try au = AudioUnitMIDISynth(soundfont: url)
          print("Valid URL: \(url)")
          let message = "Prepared Sound Font"
          result(message)
        } catch {
          print(error)
          result(FlutterError(code: "PREPARE_MIDI", message: error.localizedDescription, details: nil))
        }
      case "change_sound":
        print("Change sound")

        // 确保 call.arguments 正确解析为 [String: String] 类型，并获取 "path"
        guard let map = call.arguments as? [String: String],
              let data = map["path"] else {
            result(FlutterError(code: "INVALID_PATH", message: "Path is missing or invalid", details: nil))
            return
        }

        // 将 path 转换为 URL
        let url = URL(fileURLWithPath: data)

        // 检查 AudioUnitMIDISynth 是否已初始化，如果未初始化，则进行初始化
        if au == nil {
            do {
                try au = AudioUnitMIDISynth(soundfont: url)
                print("AudioUnitMIDISynth initialized with URL: \(url)")
            } catch {
                print("Failed to initialize AudioUnitMIDISynth: \(error.localizedDescription)")
                result(FlutterError(code: "INITIALIZATION_ERROR", message: "Failed to initialize AudioUnitMIDISynth", details: error.localizedDescription))
                return
            }
        }

        // 尝试准备 soundfont
        do {
            try au.prepare(soundfont: url)
            print("Valid URL: \(url)")
            result("Prepared Sound Font")
        } catch {
            print("Failed to prepare soundfont: \(error.localizedDescription)")
            result(FlutterError(code: "CHANGE_SOUND", message: "Failed to prepare soundfont", details: error.localizedDescription))
        }
      case "unmute":
        do {
          try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
          let message = "unmuted Device"
          result(message)
        } catch {
            print(error)
            result(FlutterError(code: "UNMUTE", message: error.localizedDescription, details: nil))
        }
      case "play_midi_note":
        _arguments = call.arguments as! [String : Any];
        do {
          let midi = _arguments["note"] as? Int
          try au.playPitch(midi:  midi ?? 60)
          let message = "Playing: \(String(describing: midi!))"
          result(message)
        } catch {
          print(error)
          result(FlutterError(code: "PLAY_MIDI_NOTE", message: error.localizedDescription, details: nil))
        }
      case "stop_midi_note":
        _arguments = call.arguments as! [String : Any];
        do {
        let midi = _arguments["note"] as? Int
        try au.stopPitch(midi:  midi ?? 60)
        let message = "Stopped: \(String(describing: midi!))"
        result(message)
        } catch {
          print(error)
          result(FlutterError(code: "STOP_MIDI_NOTE", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
        break
    }
  }
}
