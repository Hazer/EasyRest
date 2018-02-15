//
//  CurlInterceptor.swift
//  RestClient
//
//  Created by Guizion Labs on 11/03/16.
//  Copyright © 2016 Guizion Labs. All rights reserved.
//

import Foundation
import Alamofire

open class CurlInterceptor: Interceptor {
    
    required public init() {}
    
    open func requestInterceptor<T>(_ api: API<T>) where T : Decodable { }
    
    open func responseInterceptor<T>(_ api: API<T>, response: DataResponse<Any>) where T : Decodable {
        switch response.result {
        case .success:
            if let curl = api.curl {
                api.logger?.info(curl)
            }
        case .failure:
            if let curl = api.curl {
                api.logger?.error(curl)
            }
        }
    }
}
