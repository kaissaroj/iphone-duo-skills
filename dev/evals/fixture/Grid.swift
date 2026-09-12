import SwiftUI
struct G: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationStack {
            ArrangementView { NavigationSplitView { Text("a") } detail: { Text("b") } } secondary: { Text("c") }
        }
        .frame(width: 390)
        .toolbar { ToolbarItem { Image(systemName: "gear") } }
    }
}
