#if canImport(MCP)
import Network
import Foundation
import Logging
import MCP

public actor TCPTransport: Transport {
    
    
    // Mandatory implementation of the Transport protocol
    public nonisolated let logger: Logger
    private let listener: NWListener
    private var connections: [NWConnection] = []
    private var messageStream: AsyncThrowingStream<Data, any Swift.Error> // Changed to any Swift.Error
    private var messageContinuation: AsyncThrowingStream<Data, any Swift.Error>.Continuation! // Changed to any Swift.Error
    
    public init(port: UInt16, logger: Logger? = nil) {
        // Logger initialization
        self.logger = logger ?? Logger(label: "mcp.tcp.transport")
        
        // NWListener configuration
        let parameters = NWParameters.tcp
        //parameters.requiredInterfaceType = .any
        self.listener = try! NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
        
        // AsyncStream initialization with explicit any Swift.Error type
        (self.messageStream, self.messageContinuation) = AsyncThrowingStream<Data, any Swift.Error>.makeStream()
        
        // Bonjour configuration
        listener.service = NWListener.Service(
            name: "MCP Server",
            type: "_mcp._tcp",
            domain: "local",
            txtRecord: nil
        )
    }
    
    public func connect() async throws {
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.logger.info("Server listening on port \(self?.listener.port?.rawValue ?? 0)")
            case .failed(let error):
                self?.logger.error("Server error: \(error.localizedDescription)")
            default: break
            }
        }
        
        listener.newConnectionHandler = { [weak self] connection in
            // Wrap actor-isolated call in a Task
            Task {
                await self?.handleNewConnection(connection)
            }
        }
        
        listener.start(queue: .main)
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        
        connection.receiveMessage { [weak self] data, _, _, _ in
            guard let data = data else { return }
            self?.messageContinuation.yield(data)
            Task {
                await self?.handleNewConnection(connection) // Keep the connection active
            }
        }
        
        connections.append(connection)
    }
    
    // Implementation of the method required by the Transport protocol
    public func receive() -> AsyncThrowingStream<Data, any Swift.Error> { // Changed to any Swift.Error
        return messageStream
    }
    
    public func send(_ data: Data) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for connection in connections {
                group.addTask {
                    try await connection.send(content: data + "\n".data(using: .utf8)!, completion: .contentProcessed({ error in
                        print("Error in sending data")
                    }))
                }
            }
            try await group.waitForAll()
        }
    }
    
    public func disconnect() async {
        listener.cancel()
        connections.forEach { $0.cancel() }
        messageContinuation.finish()
    }
}
#endif
