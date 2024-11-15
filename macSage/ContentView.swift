import SwiftUI

struct ContentView: View {
    let API_KEY: String
    let EMAIL: String
    
    @State private var models: [String] = [] // List of models
    @State private var selectedModel: String = "" // Currently selected model
    @State private var errorMessage: String? // For displaying errors

    init() {
        API_KEY = getConfigValue(forKey: "API_KEY") ?? ""
        EMAIL = getConfigValue(forKey: "EMAIL") ?? ""
    }

    
    
    
    var body: some View {
            VStack {
                Text("Available Models")
                    .font(.headline)
                    .padding()

                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }

                // Dropdown menu for models
                if models.isEmpty {
                    Text("No models available.").padding()
                } else {
                    Picker("Select a Model", selection: $selectedModel) {
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                }

                Button("Fetch Models") {
                    fetchModels()
                }
                .padding()
            }
            .padding()
        }
    
    
    
    // Fetch Models
    func fetchModels() {
        let url = URL(string: "https://api.asksage.ai/server/get-models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add necessary headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received."
                }
                return
            }

            // Log the raw response for debugging
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }

            // Parse the models from the "response" key
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["response"] as? [String] { // Access "response" directly
                    DispatchQueue.main.async {
                        self.models = models
                        self.selectedModel = models.first ?? "" // Set default selection
                        self.errorMessage = nil // Clear any previous errors
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to parse models. Unexpected response format."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "JSON Parsing Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }}

    func getConfigValue(forKey key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        return dictionary[key] as? String
    }

#Preview {
    ContentView()
}
