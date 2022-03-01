import SwiftUI

protocol OneStepViewModelProtocol: ObservableObject {
    var photos: [UIImage] { get }
    var buttonText: String { get }
    
    func buttonAction()
}

struct ContentView<ViewModel: OneStepViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(viewModel.photos, id: \.self) {
                        Image(uiImage: $0)
                            .resizable()
                            .frame(height: 200.0)
                    }
                }
                .padding(8.0)
                .toolbar {
                    Button(viewModel.buttonText, action: viewModel.buttonAction)
                }
            }
            .navigationTitle("OneStep")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    class ViewModel: OneStepViewModelProtocol {
        let photos: [UIImage]
        @Published var buttonText: String = "Start"
        
        init() {
            photos = ["Cannes", "Rax", "Titlis"]
                .map { UIImage(named: $0) }
                .compactMap { $0 }
        }
        
        func buttonAction() {
            buttonText = buttonText == "Start" ? "Stop" : "Start"
        }
    }

    static var previews: some View {
        ContentView(viewModel: ViewModel())
    }
}
