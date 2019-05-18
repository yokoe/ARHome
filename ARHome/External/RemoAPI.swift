import UIKit
import Alamofire

extension DataRequest {
    @discardableResult
    public func responseAPIResult(queue: DispatchQueue = .main,
                                  options: JSONSerialization.ReadingOptions = .allowFragments,
                                  completionHandler: @escaping (String?, Error?) -> Void) -> Self {
        return responseJSON(queue: queue,
                            options: options,
                            completionHandler: { (res) in
                                switch res.result {
                                case .success(let value):
                                    guard let response = res.response else {
                                        completionHandler(nil, NSError(domain: "RemoAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "No response"]))
                                        return
                                    }
                                    if response.statusCode != 200 {
                                        completionHandler(nil, NSError(domain: "RemoAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Status code: \(response.statusCode)"]))
                                        return
                                    }
                                    if let dic = value as? NSDictionary {
                                        completionHandler(dic.description, nil)
                                    } else {
                                        completionHandler(nil, NSError(domain: "RemoAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Response is not dictionary"]))
                                    }
                                case .failure(let error):
                                    completionHandler(nil, error)
                                }
        })
    }
}

class RemoAPI {
    private var accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    private var requestHeaders: HTTPHeaders {
        return [
            "Authorization": "Bearer \(accessToken)",
            "Accept": "application/json"
        ]
    }
    
    private func requestURL(forPath path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.nature.global"
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
    
    private func postRequest(forPath path: String, queryItems: [URLQueryItem]? = nil) -> DataRequest? {
        guard let url = requestURL(forPath: path, queryItems: queryItems) else {
            debugPrint("Failed to construct request url for path \(path)")
            return nil
        }
        return AF.request(url, method: .post, headers: requestHeaders).validate(statusCode: 200..<300)
    }
    
    func sendSignal(_ signalID: String, completionHandler: @escaping (String?, Error?) -> Void) {
        guard let req = postRequest(forPath: "/1/signals/\(signalID)/send") else {
            completionHandler(nil, NSError(domain: "RemoAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create request."]))
            return
        }
        req.responseAPIResult(completionHandler: completionHandler)
    }
    
    func sendACSettings(applianceID: String, temperature: Int?, button: String?, completionHandler: @escaping (String?, Error?) -> Void) {
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "button", value: button)]
        if let temperature = temperature {
            queryItems.append(URLQueryItem(name: "temperature", value: String(temperature)))
        }
        guard let req = postRequest(forPath: "/1/appliances/\(applianceID)/aircon_settings", queryItems: queryItems) else {
            completionHandler(nil, NSError(domain: "RemoAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create request."]))
            return
        }
        req.responseAPIResult(completionHandler: completionHandler)
    }
}
