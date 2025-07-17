import Foundation

print("🧪 Testing Option 1 redirect behavior...")

// Test 1: URLSession with no custom delegate (standard behavior)
print("\n📋 Test 1: Standard URLSession (no custom delegate)")

let session1 = URLSession.shared
let url1 = URL(string: "https://httpbin.org/redirect-to?url=https://httpbin.org/get&status_code=302")!
let request1 = URLRequest(url: url1)

let task1 = session1.dataTask(with: request1) { data, response, error in
    if let error = error {
        print("❌ Error: \(error.localizedDescription)")
    } else if let httpResponse = response as? HTTPURLResponse {
        print("✅ Response received:")
        print("   Status: \(httpResponse.statusCode)")
        print("   URL: \(httpResponse.url?.absoluteString ?? "unknown")")
        
        if httpResponse.statusCode == 200 {
            print("   🎯 Redirect was followed (expected behavior)")
        } else if httpResponse.statusCode == 302 {
            print("   🔄 Got redirect response (may indicate Option 1 issue)")
        }
    }
    
    // Test 2: URLSession with custom delegate that blocks redirects
    print("\n📋 Test 2: URLSession with custom redirect delegate")
    
    class TestDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            print("🔄 Custom delegate called!")
            print("   Redirect status: \(response.statusCode)")
            print("   Location: \(response.value(forHTTPHeaderField: "Location") ?? "none")")
            print("   Blocking redirect...")
            
            // Block the redirect
            completionHandler(nil)
        }
    }
    
    let delegate = TestDelegate()
    let session2 = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    
    let task2 = session2.dataTask(with: request1) { data, response, error in
        if let error = error {
            print("⚠️ Request completed with error: \(error.localizedDescription)")
            print("   (This might be expected when blocking redirects)")
        } else if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response received:")
            print("   Status: \(httpResponse.statusCode)")
            print("   URL: \(httpResponse.url?.absoluteString ?? "unknown")")
            
            if httpResponse.statusCode == 302 {
                print("   🎯 Got redirect response as expected (custom handling worked)")
            } else {
                print("   ❓ Unexpected status code")
            }
        }
        
        print("\n🏁 Test completed")
        exit(0)
    }
    
    task2.resume()
}

task1.resume()

// Keep the program running
RunLoop.main.run()
