struct MainSceneRoot: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    
    var body: some View {
        ContentView()
            .environmentObject(viewModel)
    }
}
