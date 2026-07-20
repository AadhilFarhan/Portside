import Foundation

@main
enum Entry {
    static func main() {
        if CLI.runIfRequested() { return }
        PortsideApp.main()
    }
}
