//
//  StatsView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 04/12/24.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject private var storage = Storage.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General Stats")) {
                    if storage.requests.isEmpty {
                        Text("No data available")
                    } else {
                        Text("**Total Requests:** \(storage.requests.count)")
                        Text("**Success Rate:** \(successRate)%")
                        Text("**Failure Rate:** \(failureRate)%")
                        Text("**Informational Responses:** \(informationalRate)%")
                        Text("**Average Response Time:** \(averageResponseTime, specifier: "%.2f") ms")
                        Text("**Fastest Request:** \(fastestRequestTime, specifier: "%.2f") ms")
                        Text("**Slowest Request:** \(slowestRequestTime, specifier: "%.2f") ms")
                        Text("**Data Sent:** \(dataSent) MB")
                        Text("**Data Received:** \(dataReceived) MB")
                    }
                }
                
                Section(header: Text("HTTP Methods Breakdown")) {
                    if httpMethodsBreakdown.isEmpty {
                        Text("No data available")
                    } else {
                        if let getPercentage = httpMethodsBreakdown["GET"] {
                            Text("**GET:** \(getPercentage, specifier: "%.2f")%")
                        }
                        if let postPercentage = httpMethodsBreakdown["POST"] {
                            Text("**POST:** \(postPercentage, specifier: "%.2f")%")
                        }
                        if let putPercentage = httpMethodsBreakdown["PUT"] {
                            Text("**PUT:** \(putPercentage, specifier: "%.2f")%")
                        }
                        if let deletePercentage = httpMethodsBreakdown["DELETE"] {
                            Text("**DELETE:** \(deletePercentage, specifier: "%.2f")%")
                        }
                        if let patchPercentage = httpMethodsBreakdown["PATCH"] {
                            Text("**PATCH:** \(patchPercentage, specifier: "%.2f")%")
                        }
                        if let headPercentage = httpMethodsBreakdown["HEAD"] {
                            Text("**HEAD:** \(headPercentage, specifier: "%.2f")%")
                        }
                        if let optionsPercentage = httpMethodsBreakdown["OPTIONS"] {
                            Text("**OPTIONS:** \(optionsPercentage, specifier: "%.2f")%")
                        }
                        if let tracePercentage = httpMethodsBreakdown["TRACE"] {
                            Text("**TRACE:** \(tracePercentage, specifier: "%.2f")%")
                        }
                        if let connectPercentage = httpMethodsBreakdown["CONNECT"] {
                            Text("**CONNECT:** \(connectPercentage, specifier: "%.2f")%")
                        }
                    }
                }
                
                Section(header: Text("Status Code Distribution")) {
                    if statusCodeDistribution.isEmpty {
                        Text("No data available")
                    } else {
                        ForEach(statusCodeDistribution.sorted(by: >), id: \.key) { code, count in
                            Text("**\(code):** \(count)")
                        }
                    }
                }
                
                Section(header: Text("Error Types")) {
                    if errorTypes.isEmpty {
                        Text("No data available")
                    } else {
                        ForEach(errorTypes.sorted(by: >), id: \.key) { error, count in
                            Text("**\(error):** \(count)")
                        }
                    }
                }
                
                Section(header: Text("Request Size Stats")) {
                    if storage.requests.isEmpty {
                        Text("No data available")
                    } else {
                        Text("**Average Request Size:** \(averageRequestSize) bytes")
                        Text("**Min Request Size:** \(minRequestSize) bytes")
                        Text("**Max Request Size:** \(maxRequestSize) bytes")
                    }
                }
                
                Section(header: Text("Response Size Stats")) {
                    if storage.requests.isEmpty {
                        Text("No data available")
                    } else {
                        Text("**Average Response Size:** \(averageResponseSize) bytes")
                        Text("**Min Response Size:** \(minResponseSize) bytes")
                        Text("**Max Response Size:** \(maxResponseSize) bytes")
                    }
                }
            }
            .navigationTitle("Request Stats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var successRate: Double {
        let successCount = storage.requests.filter { $0.code >= 200 && $0.code < 300 }.count
        return (Double(successCount) / Double(storage.requests.count)) * 100
    }
    
    private var failureRate: Double {
        let failureCount = storage.requests.filter { $0.code >= 400}.count
        return (Double(failureCount) / Double(storage.requests.count)) * 100
    }
    
    private var informationalRate: Double {
        let informationalCount = storage.requests.filter { $0.code < 200 }.count
        return (Double(informationalCount) / Double(storage.requests.count)) * 100
    }
    
    private var averageResponseTime: Double {
        let totalDuration = storage.requests.compactMap { $0.duration }.reduce(0, +)
        return totalDuration / Double(storage.requests.count)
    }
    
    private var fastestRequestTime: Double {
        storage.requests.compactMap { $0.duration }.min() ?? 0
    }
    
    private var slowestRequestTime: Double {
        storage.requests.compactMap { $0.duration }.max() ?? 0
    }
    
    private var dataSent: Double {
        let totalBytesSent = storage.requests.compactMap { $0.countOfRequestBodyBytesSent }.reduce(0, +)
        return Double(totalBytesSent) / (1024 * 1024)
    }
    
    private var dataReceived: Double {
        let totalBytesReceived = storage.requests.compactMap { $0.countOfResponseBodyBytesReceived }.reduce(0, +)
        return Double(totalBytesReceived) / (1024 * 1024)
    }
    
    private var httpMethodsBreakdown: [String: Double] {
        let methodCounts = storage.requests.reduce(into: [String: Int]()) { counts, request in
            counts[request.method, default: 0] += 1
        }
        return methodCounts.mapValues { (Double($0) / Double(storage.requests.count)) * 100 }
    }
    
    private var statusCodeDistribution: [Int: Int] {
        storage.requests.reduce(into: [Int: Int]()) { counts, request in
            counts[request.code, default: 0] += 1
        }
    }
    
    private var errorTypes: [String: Int] {
        storage.requests.compactMap { $0.errorClientDescription }.reduce(into: [String: Int]()) { counts, error in
            counts[error, default: 0] += 1
        }
    }
    
    private var averageRequestSize: Int {
        let totalSize = storage.requests.compactMap { $0.httpBody?.count }.reduce(0, +)
        return totalSize / max(storage.requests.count, 1)
    }
    
    private var minRequestSize: Int {
        storage.requests.compactMap { $0.httpBody?.count }.min() ?? 0
    }
    
    private var maxRequestSize: Int {
        storage.requests.compactMap { $0.httpBody?.count }.max() ?? 0
    }
    
    private var averageResponseSize: Int {
        let totalSize = storage.requests.compactMap { $0.dataResponse?.count }.reduce(0, +)
        return totalSize / max(storage.requests.count, 1)
    }
    
    private var minResponseSize: Int {
        storage.requests.compactMap { $0.dataResponse?.count }.min() ?? 0
    }
    
    private var maxResponseSize: Int {
        storage.requests.compactMap { $0.dataResponse?.count }.max() ?? 0
    }
}

#Preview {
    StatsView()
}
