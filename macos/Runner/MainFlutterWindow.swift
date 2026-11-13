import Cocoa
import FlutterMacOS
import Security

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let keychain = FlutterMethodChannel(name: "backomat/keychain", binaryMessenger: flutterViewController.engine.binaryMessenger)
    keychain.setMethodCallHandler { call, result in
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.joel.backomat.openai",
        kSecAttrAccount as String: "api-key"
      ]
      switch call.method {
      case "read":
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &item)
        if status == errSecItemNotFound { result(nil) }
        else if status == errSecSuccess, let data = item as? Data { result(String(data: data, encoding: .utf8)) }
        else { result(FlutterError(code: "keychain", message: "Keychain read failed", details: status)) }
      case "write":
        guard let value = call.arguments as? String else {
          result(FlutterError(code: "keychain", message: "Missing key", details: nil)); return
        }
        let attributes: [String: Any] = [kSecValueData as String: Data(value.utf8)]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
          var entry = query
          entry[kSecValueData as String] = Data(value.utf8)
          entry[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
          status = SecItemAdd(entry as CFDictionary, nil)
        }
        if status == errSecSuccess { result(nil) }
        else { result(FlutterError(code: "keychain", message: "Keychain write failed", details: status)) }
      case "delete":
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { result(nil) }
        else { result(FlutterError(code: "keychain", message: "Keychain delete failed", details: status)) }
      default: result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
