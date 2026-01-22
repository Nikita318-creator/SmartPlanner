import Foundation

struct Config: Codable, Sendable {
    let isPaid: Bool
}

final class ConfigService {
    static let shared = ConfigService()
    private init() {}

    private let configURL = URL(string: "https://raw.githubusercontent.com/Nikita318-creator/analitics-data/main/SmartPlanner.json")
    
    func checkAccess(completion: @escaping (Bool) -> Void) {
        guard let url = configURL else { return }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let remoteConfig = try? JSONDecoder().decode(Config.self, from: data) else {
                DispatchQueue.main.async { completion(true) }
                return
            }
            
            DispatchQueue.main.async {
                completion(remoteConfig.isPaid)
            }
        }.resume()
    }
}
