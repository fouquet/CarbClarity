//
//  LookupAPI.swift
//  CarbClarity
//
//  Created by René Fouquet on 16.06.24.
//

import Foundation

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

protocol LookupAPIProtocol: Sendable {
    var apiKey: String { get }
    func search(for string: String) async throws -> [CarbFood]
    func fetchFoodDetail(fdcId: Int) async throws -> Double?
}

final class LookupAPI: LookupAPIProtocol {
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    let apiKey: String
    let session: URLSessionProtocol

    init(apiKey: String, session: URLSessionProtocol = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func request(with path: String, method: Method) -> URLRequest? {
        guard let URL = URL(string: "https://api.nal.usda.gov/fdc/v1" + path) else { return nil }
        var request = URLRequest(url: URL)
        request.httpMethod = method.rawValue
        request.addValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        return request
    }
    
    private func validateHTTPResponse(_ response: URLResponse, allowNotFound: Bool = false) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw NSError(
                domain: "LookupAPI",
                code: httpResponse.statusCode,
                userInfo: [
                    "response": httpResponse,
                    NSLocalizedDescriptionKey: "Invalid API key"
                ]
            )
        case 404 where allowNotFound:
            // Special case: 404 is handled differently for lookup requests
            throw NotFoundError()
        case 400...499:
            throw NSError(
                domain: "LookupAPI", 
                code: httpResponse.statusCode,
                userInfo: [
                    "response": httpResponse,
                    NSLocalizedDescriptionKey: "Request error"
                ]
            )
        case 500...599:
            throw NSError(
                domain: "LookupAPI",
                code: httpResponse.statusCode, 
                userInfo: [
                    "response": httpResponse,
                    NSLocalizedDescriptionKey: "Server error"
                ]
            )
        default:
            throw NSError(
                domain: "LookupAPI",
                code: httpResponse.statusCode,
                userInfo: [
                    "response": httpResponse,
                    NSLocalizedDescriptionKey: "Unknown error"
                ]
            )
        }
    }
    
    private struct NotFoundError: Error {}
    
    func search(for string: String) async throws -> [CarbFood] {
        let path = "/foods/search"
        
        guard var request = request(with: path, method: .post) else { 
            throw URLError(.badURL)
        }
                
        let bodyObject: [String : Any] = [
            "query": string,
            "dataType": [
                "Foundation"
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyObject, options: [])
        
        let (data, response) = try await session.data(for: request)
        
        try validateHTTPResponse(response)
        
        guard let foodLookup = try? JSONDecoder().decode(FoodLookup.self, from: data) else {
            throw NSError(
                domain: "LookupAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"]
            )
        }
        
        return foodLookup.foods.compactMap({ food in
            let carbValue = food.carbs()
            let hasCarbs = carbValue > 0
            return CarbFood(
                name: food.description,
                carbs: carbValue,
                fdcId: food.fdcID,
                isLoadingCarbs: !hasCarbs
            )
        })
    }
    
    func fetchFoodDetail(fdcId: Int) async throws -> Double? {
        guard let request = request(with: "/food/\(fdcId)?nutrients=1005", method: .get) else { 
            throw URLError(.badURL)
        }
                
        let (data, response) = try await session.data(for: request)
        
        do {
            try validateHTTPResponse(response, allowNotFound: true)
        } catch is NotFoundError {
            return nil
        }
        
        guard let food = try? JSONDecoder().decode(Food.self, from: data) else {
            return nil
        }
        
        return food.carbs()
    }
}
