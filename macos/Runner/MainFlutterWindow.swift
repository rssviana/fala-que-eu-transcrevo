import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Tamanho do design: 1120 × 780, mínimo 720 × 600, centralizada.
    self.setContentSize(NSSize(width: 1120, height: 780))
    self.contentMinSize = NSSize(width: 720, height: 600)
    self.title = "Fala que eu transcrevo!"
    self.backgroundColor = NSColor(red: 0x0C / 255.0, green: 0x0E / 255.0, blue: 0x13 / 255.0, alpha: 1)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
