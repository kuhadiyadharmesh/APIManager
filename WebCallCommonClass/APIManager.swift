//
//  APIManager.swift
//  WebCallCommonClass
//
//  Created by mac-2 on 20/05/19.
//  Copyright © 2019 mac-2. All rights reserved.
//

import Foundation
import SystemConfiguration
import UIKit

enum MethodType: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

enum ResponseType {
    case successResponse([String: Any])
    case failureResponse(Error)
}

struct MultipartObject {
    var name: String
    var mimeType: String
    var fileName: String
    var data: Data
}

class APIManager {
    
    
    //MARK: Variables
    private var showActivityIndicator = true
    private var headers = [String : String]()
    private var baseUrl = "http://192.168.0.102:821/taste/"
    private var apiName = ""
    private var fullUrlString = ""
    private var httpMethod: MethodType = .get
    private var requestTimeOutInterval:TimeInterval = 96
    private var parametres: [String: Any]?
    private var files = [MultipartObject]()
    
    
    typealias networkHandler = (ResponseType) -> ()
    private var completionCallBack: networkHandler?
    
    init() {
        
        headers = ["authorization": "sadker8JK80wONWRKjgjTCMldZ.eyJpZCMSwidehwYYALkc8KLEaczE5MzAZjMyMTU4ODA5NjFlOTVmIiwiZGF0ZSI6MTUwNDcxOJpZfdYENC093kfGHxNTA0NzE5MzAyfQ.tBJpZIRH9Kegdfkj5MzI5YjMldZW0NzQC9Q"]

    }
    
    
    // MARK: For additional functionality
    
    convenience init(httpMethod:MethodType, apiName: String, headers: [String : String],  params: [String: Any]?) {
        self.init()
        self.httpMethod = httpMethod
        self.apiName = apiName
        guard let encodedUrl = apiName.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed) else {
            return
        }
        self.fullUrlString = baseUrl + encodedUrl
        self.parametres = params
        
        self.headers = headers
        
    }
    
    convenience init(httpMethod:MethodType, apiName: String, headers: [String : String],  params: [String: Any]?, files: [MultipartObject]) {
        self.init()
        self.httpMethod = httpMethod
        self.apiName = apiName
        guard let encodedUrl = apiName.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed) else {
            return
        }
        self.files = files
        self.fullUrlString = baseUrl + encodedUrl
        self.parametres = params
        
        self.headers = headers
        
    }

    // MARK: Completion Callback
    public func completion(callback: @escaping networkHandler) {
        completionCallBack = callback
        if files.isEmpty {
            startRequest()
            return
        }
        startMultipartRequest()
    }
    
    
    // MARK: Creating Request
    private func startRequest() {
        guard let url = URL(string: fullUrlString) else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.timeoutInterval = self.requestTimeOutInterval
        let session = URLSession(configuration: .default)
        
        switch httpMethod {
        case .post, .put:
            do {
                if let params = parametres {
                    request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
                }
                
            } catch {
                
            }
            
        default:
            print("other methods")
        }
        
        //for adding headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        startDataTask(session: session, request: request)
    }
    
    private func startMultipartRequest() {
        
        let boundary = "----WebKitFormBoundarycC4YiaUFwM44F6rT"
        var body = Data()
        if let params = self.parametres {
            for (key, value) in params {
                body.append(("--\(boundary)\r\n").data(using: String.Encoding.utf8, allowLossyConversion: true)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
                body.append("\(value)\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
            }
        }
        for file in self.files {
            body.append(("--\(boundary)\r\n").data(using: String.Encoding.utf8, allowLossyConversion: true)!)
            body.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n" .data(using: String.Encoding.utf8, allowLossyConversion: true)!)
            body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
            body.append(file.data)
            body.append("\r\n".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
        }
        
        body.append("--\(boundary)--".data(using: String.Encoding.utf8, allowLossyConversion: true)!)
        guard let url = URL(string: fullUrlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.httpBody = body
        request.timeoutInterval = self.requestTimeOutInterval
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        //for adding headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        let session = URLSession(configuration: .default)
        
        startDataTask(session: session, request: request)
        
    }
    
    // MARK: for completing task
    private func startDataTask(session: URLSession, request: URLRequest) {
        
        if showActivityIndicator {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard error == nil else {
                    self.completionCallBack?(ResponseType.failureResponse(error!))
                    return
                }
                var jsonObject: [String: Any]?
                guard let data = data else {
                    return
                }
                do {
                    let  json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    jsonObject = json
                    
                } catch {
                    let error = self.errorWithDescription(description: "Serialization error", code: 20)
                    self.completionCallBack?(ResponseType.failureResponse(error))
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    return
                }
                self.handleCases(statusCode: response.statusCode, json: jsonObject)
            }
        }
        
        task.resume()
    }
    
    
    // MARK: Handling cases
    private func handleCases(statusCode: Int, json: [String: Any]?) {
        guard let json = json else {
            return
        }
        
        switch statusCode {
        case 200...300:
            self.completionCallBack?(ResponseType.successResponse(json))
        case 401:
            print("unauthorised")
        default:
            handleErrorCases(json: json, statusCode: statusCode)
        }
    }
    
    
    private func handleErrorCases(json: [String: Any], statusCode: Int) {
        guard let message = json["message"] as? String else {
            let error = errorWithDescription(description: "Error", code: statusCode)
            self.completionCallBack?(ResponseType.failureResponse(error))
            return
        }
        let error = errorWithDescription(description: message, code: statusCode)
        self.completionCallBack?(ResponseType.failureResponse(error))
    }
    
    private func errorWithDescription(description: String, code: Int) -> Error {
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: "app", code: code, userInfo: userInfo) as Error
    }
}

extension Dictionary {
    
    //Append Dictionary
    mutating func appendDictionary(other: Dictionary) {
        for (key, value) in other {
            self.updateValue(value, forKey:key)
        }
    }
    
    static func += <K, V> ( left: inout [K:V], right: [K:V]) {
        for (k, v) in right {
            left.updateValue(v, forKey: k)
        }
    }
    
}
