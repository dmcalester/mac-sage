import SwiftUI

struct ContentView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("username") private var username: String = ""
    
    
    
    // Key constants for UserDefaults
    private var modelsKey: String { "storedModels" }
    private var lastUpdateKey: String { "lastModelUpdate" }
    
    @State private var models: [String] = [] // List of models
    @State private var selectedModel: String = "" // Currently selected model
    @State private var userPrompt: String = "" // User input for the prompt
    @State private var responseText: String = "" // Response text
    @State private var errorMessage: String? // For displaying errors
    @State private var showSettings = false // For toggling settings view
    

    
    
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
            "dataset": "none",
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
        request.addValue(apiKey, forHTTPHeaderField: "x-access-tokens")
        
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
            // Display response text
            VStack(alignment: .leading) {

                TextEditor(text: $responseText)
                    .frame(height: 100.0)
                    .border(Color.gray, width: 1)
                    .textSelection(.enabled)
                    .padding()
            }
            // Dropdown menu for models
            if models.isEmpty {
                Text("No models available.").padding()
            } else {
                Picker("", selection: $selectedModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 10.0)
                .padding(.vertical, 0)
            }
            
            // User prompt input field
            VStack(alignment: .leading) {
    
                TextField("Type your prompt here...", text: $userPrompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            .padding(0.0)
            
            
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
          
            
            Button("Submit Prompt") {
                submitPrompt()
            }
            .padding()
            
            
            
            Button("Settings") {
                showSettings.toggle()
               }
            .padding()
            .sheet(isPresented: $showSettings) {
                SettingsView() {
                    fetchModels()
                }
            }
        }
        .padding()
        .onAppear {
            if apiKey.isEmpty {
               showSettings = true // Open settings if API key is not set
           } else {
               fetchModels() // Automatically fetch models when the view appears
           }
        }
    }
    
    
    
    // Check if we need to fetch from the server
    private func shouldFetchFromServer() -> Bool {
        if let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastUpdate)
            return elapsedTime > 24 * 60 * 60 // 24 hours in seconds
        }
        return true // No record of last update
    }
    
    // Fetch models from the server
    private func fetchModelsFromServer() {
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
            
            // Parse the models from the "response" key
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["response"] as? [String] { // Access "response" directly
                    DispatchQueue.main.async {
                        self.models = models
                        // Default to "gpt-40-mini" if available, otherwise select the first model
                        self.selectedModel = models.contains("gpt-4o-mini") ? "gpt-4o-mini" : models.first ?? ""
                        self.errorMessage = nil // Clear any previous errors
                        self.saveModelsToLocal(models)
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
    }
    
    // Save models to local storage
    private func saveModelsToLocal(_ models: [String]) {
        UserDefaults.standard.set(models, forKey: modelsKey)
        UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
    }
    
    // Load models from local storage
    private func loadModelsFromLocal() {
        if let storedModels = UserDefaults.standard.array(forKey: modelsKey) as? [String] {
            self.models = storedModels
            self.selectedModel = storedModels.contains("gpt-4o-mini") ? "gpt-4o-mini" : storedModels.first ?? ""
        } else {
            self.models = []
            self.selectedModel = ""
            self.errorMessage = "No locally stored models available."
        }
    }
    
    
    // Fetch Models
    func fetchModels() {
        // Check if the models need to be updated
        if shouldFetchFromServer() {
            print("Fetching models from server...")
            fetchModelsFromServer()
        } else {
            print("Loading models from local storage...")
            loadModelsFromLocal()
        }
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
