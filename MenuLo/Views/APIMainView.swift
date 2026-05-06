import SwiftUI

struct APIMainView: View {
    @AppStorage("authToken") private var token: String = ""
    
    var body: some View {
        Group {
            if token.isEmpty {
                APILoginView()
            } else {
                RestaurantListView()
            }
        }
    }
}

struct RestaurantListView: View {
    @AppStorage("authToken") private var token: String = ""
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List(restaurants) { restaurant in
                VStack(alignment: .leading, spacing: 5) {
                    Text(restaurant.businessName)
                        .font(.headline)
                    if let address = restaurant.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Restoranlar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Çıkış Yap") {
                        token = ""
                    }
                }
            }
            .overlay {
                if isLoading { ProgressView() }
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            restaurants = try await NetworkManager.shared.fetchRestaurants()
        } catch {
            print("Veri çekilemedi: \(error)")
        }
        isLoading = false
    }
}
