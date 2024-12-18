import Foundation
import SwiftSoup

/// 接收關鍵字字串 (空白分隔)，向Google搜尋並取得前50筆結果 (title -> url)。
class GoogleQuery {
    private var queryKeywords: String
    private var url: String
    private var content: String?
    
    init(queryKeywords: String) {
        self.queryKeywords = queryKeywords
        if let encodedKeyword = queryKeywords.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            self.url = "https://www.google.com/search?q=\(encodedKeyword)&oe=utf8&num=50"
        } else {
            self.url = ""
            print("Error encoding query keywords.")
        }
    }
    
    private func fetchContent() throws -> String {
        guard let url = URL(string: self.url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Chrome/107.0.5304.107", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        if let html = String(data: data, encoding: .utf8) {
            return html
        } else {
            throw URLError(.cannotDecodeRawData)
        }
    }
    
    private func cleanUrl(_ url: String) -> String {
        if let endIndex = url.firstIndex(of: "&") {
            return String(url[..<endIndex])
        }
        return url
    }
    
    private func isValidUrl(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0
        
        let semaphore = DispatchSemaphore(value: 0)
        var isValid = false
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                isValid = true
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        return isValid
    }
    
    func query() throws -> [String: String] {
        if content == nil {
            content = try fetchContent()
        }
        
        guard let content = content else { return [:] }
        
        var resultMap: [String: String] = [:]
        let doc = try SwiftSoup.parse(content)
        let elements = try doc.select("div").select(".kCrYT")
        
        for element in elements {
            do {
                if let linkElement = try element.select("a").first(),
                   let citeUrl = try linkElement.attr("href").replacingOccurrences(of: "/url?q=", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let title = try linkElement.select(".vvjwJb").text(), !title.isEmpty, isValidUrl(citeUrl) {
                    
                    resultMap[title] = cleanUrl(citeUrl)
                }
            } catch {
                // Ignore invalid elements
            }
        }
        return resultMap
    }
}
