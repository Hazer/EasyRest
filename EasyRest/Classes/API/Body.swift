//
//  Body.swift
//  Alamofire
//
//  Created by Vithorio Polten on 15/02/18.
//

import Foundation

public enum Body {
    case codable(Encodable)
    case params([String: Any]?)
}
