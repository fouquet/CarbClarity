//
//  LookupError.swift
//  CarbClarity
//
//  Created by René Fouquet on 12.07.25.
//

import Foundation

enum LookupError: LocalizedError, Equatable {
    case networkUnavailable
    case timeout
    case noAPIKey
    case invalidAPIKey
    case serverError(Int)
    case parseError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No Internet Connection"
        case .timeout:
            return "Request Timed Out"
        case .noAPIKey:
            return "API Key Missing"
        case .invalidAPIKey:
            return "Invalid API Key"
        case .serverError(let code):
            return "Server Error (\(code))"
        case .parseError:
            return "Data Format Error"
        case .unknown(let message):
            return "Unexpected Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .noAPIKey:
            return "Please add your USDA API key in Settings."
        case .invalidAPIKey:
            return "Please check your API key in Settings."
        case .serverError:
            return "The food database is temporarily unavailable. Please try again later."
        case .parseError:
            return "There was a problem processing the food data. Please try again."
        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .networkUnavailable, .timeout, .serverError, .parseError, .unknown:
            return true
        case .noAPIKey, .invalidAPIKey:
            return false
        }
    }
    
    static func from(_ error: Error) -> LookupError {
        let nsError = error as NSError
        
        // Check for custom API errors first
        if nsError.domain == "LookupAPI" {
            if nsError.localizedDescription.contains("No API key") {
                return .noAPIKey
            }
            if nsError.localizedDescription.contains("Failed to parse") {
                return .parseError
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            default:
                return .unknown(urlError.localizedDescription)
            }
        }
        
        if let httpResponse = nsError.userInfo["response"] as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401, 403:
                return .invalidAPIKey
            case 400...499:
                return .serverError(httpResponse.statusCode)
            case 500...599:
                return .serverError(httpResponse.statusCode)
            default:
                return .unknown("HTTP \(httpResponse.statusCode)")
            }
        }
        
        return .unknown(error.localizedDescription)
    }
}
