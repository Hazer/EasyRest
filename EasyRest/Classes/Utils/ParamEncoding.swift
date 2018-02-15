//
//  ParamEncoding.swift
//  Alamofire
//
//  Created by Vithorio Polten on 15/02/18.
//

import Foundation
import Alamofire

public struct JsonEncodableParameters: ParameterEncoding {
    public static let `default`: ParameterEncoding = {
        return JsonEncodableParameters(dateEncodingStrategy: .iso8601, dataEncodingStrategy: .base64)
    }()
    
    let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy?
    let dataEncodingStrategy: JSONEncoder.DataEncodingStrategy?
    let nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy?
    let outputFormatting: JSONEncoder.OutputFormatting?
    let userInfo: [CodingUserInfoKey : Any]?
    
    init(dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil,
         dataEncodingStrategy: JSONEncoder.DataEncodingStrategy? = nil,
         nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy? = nil,
         outputFormatting: JSONEncoder.OutputFormatting? = nil,
         userInfo: [CodingUserInfoKey : Any]? = nil) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
        self.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        self.outputFormatting = outputFormatting
        self.userInfo = userInfo
    }
    
    private func BuildEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        if let dateEncodingStrategy = dateEncodingStrategy {
            encoder.dateEncodingStrategy = dateEncodingStrategy
        }
        if let dataEncodingStrategy = dataEncodingStrategy {
            encoder.dataEncodingStrategy = dataEncodingStrategy
        }
        if let nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy {
            encoder.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        }
        if let outputFormatting = outputFormatting {
            encoder.outputFormatting = outputFormatting
        }
        if let userInfo = userInfo {
            encoder.userInfo = userInfo
        }
        return encoder
    }
    
    struct DynamicKey: CodingKey {
        var stringValue: String
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        // No need to support int based containers for JSON
        let intValue: Int? = nil
        init?(intValue: Int) {
            return nil
        }
    }
    
    struct ParameterWrapper: Encodable {
        let parameters: Parameters
        
        init?(_ parameters: Parameters?) {
            guard let parameters = parameters else { return nil }
            self.parameters = parameters
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicKey.self)
            for (k, v) in parameters {
                guard let value = v as? Encodable else {
                    let ctx = EncodingError.Context(codingPath: container.codingPath,
                                                    debugDescription: "Trying to cast '{k}' to Encodable")
                    throw EncodingError.invalidValue(v, ctx)
                }
                // Empty key signifies root object
                if k == "" {
                    try value.encode(to: encoder)
                } else {
                    let key = DynamicKey(stringValue: k)
                    try value.encode(to: container.superEncoder(forKey: key))
                }
            }
        }
    }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        guard let parameters = ParameterWrapper(parameters) else { return urlRequest }
        do {
            let data = try BuildEncoder().encode(parameters)
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            urlRequest.httpBody = data
        } catch {
            throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
        return urlRequest
    }
}

public extension SessionManager {
    @discardableResult
    open func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Encodable? = nil,
        encoding: ParameterEncoding = JsonEncodableParameters.default,
        headers: HTTPHeaders? = nil)
        -> DataRequest
    {
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: headers)
            let encodedURLRequest = try encoding.encode(urlRequest, with: ["": parameters])
            return request(encodedURLRequest)
        } catch {
            return request(failedWith: error)
        }
    }
}
