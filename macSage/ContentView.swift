import SwiftUI

struct ContentView: View {
    let API_KEY: String
    let EMAIL: String
    
    @State private var models: [String] = [] // List of models
    @State private var selectedModel: String = "" // Currently selected model
    @State private var userPrompt: String = "" // User input for the prompt
    @State private var responseText: String = "" // Response text
    @State private var errorMessage: String? // For displaying errors

    init() {
        API_KEY = getConfigValue(forKey: "API_KEY") ?? ""
        EMAIL = getConfigValue(forKey: "EMAIL") ?? ""
    }

    
    // Handle prompt submission
    func submitPrompt() {
        guard !userPrompt.isEmpty else {
            errorMessage = "Prompt cannot be empty."
            return
        }
        guard !selectedModel.isEmpty else {
            errorMessage = "Please select a model."
            return
        }

        let url = URL(string: "https://api.asksage.ai/server/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Prepare the payload
        let payload: [String: Any] = [
            "model": selectedModel,
            "message": userPrompt
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            errorMessage = "Failed to encode payload."
            return
        }

        // Add headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(API_KEY, forHTTPHeaderField: "x-access-tokens")

        // Make the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received."
                }
                return
            }

            // Parse and handle the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Full Response: \(json)") // Debugging log

                    if let completion = json["response"] as? String, completion == "OK",
                       let message = json["message"] as? String {
                        DispatchQueue.main.async {
                            self.responseText = message // Display the message as response
                            self.errorMessage = nil
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Unexpected response format: \(json)"
                            self.responseText = "Error: Unable to retrieve completion."
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "JSON Parsing Error: \(error.localizedDescription)"
                    self.responseText = "Failed to parse server response."
                }
            }
        }.resume()
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

            // Display response text
            VStack(alignment: .leading) {
                Text("Response:")
                    .font(.subheadline)
                    .padding(.bottom, 2)

                TextEditor(text: $responseText)
                    .frame(height: 100)
                    .border(Color.gray, width: 1)
                    .padding()
                    .disabled(true) // Prevent editing
            }

            // User prompt input field
            VStack(alignment: .leading) {
                Text("Enter your prompt:")
                    .font(.subheadline)
                    .padding(.bottom, 2)

                TextField("Type your prompt here...", text: $userPrompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            
            Button("Submit Prompt") {
                submitPrompt()
            }
            .padding()            }
            .padding()
            .onAppear {
                fetchModels() // Automatically fetch models when the view appears
            }
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
                        // Default to "gpt-40-mini" if available, otherwise select the first model
                       self.selectedModel = models.contains("gpt-4o-mini") ? "gpt-4o-mini" : models.first ?? ""
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
