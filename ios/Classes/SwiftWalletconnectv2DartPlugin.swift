import Flutter
import UIKit
import WalletConnectSwiftV2

extension String: Error {}

public class SwiftWalletconnectv2DartPlugin: NSObject, FlutterPlugin, WalletConnectClientDelegate {
    
    var client: WalletConnectClient?
    var channel: FlutterMethodChannel?
    var proposalId: uint = 0
    var proposals: [uint: SessionProposal] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "walletconnectv2_dart", binaryMessenger: registrar.messenger())
        let instance = SwiftWalletconnectv2DartPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("walletconectv2 handle", call.method, call.arguments)
        do{
            switch call.method {
            case "init":
                try onInit(call, result: result)
            case "pair":
                if self.client == nil {
                    throw "尚未初始化"
                }
                guard let uri = call.arguments as? String else {
                    throw "传递参数异常"
                }
                try self.client!.pair(uri: uri)
            case "approveProposal":
                if self.client == nil {
                    throw "尚未初始化"
                }
                guard let arguments = call.arguments as? [String: Any] else {
                    throw "传递参数异常"
                }
                let proposalId = arguments["proposalId"] as! uint
                if (self.proposals.index(forKey: proposalId) == nil) {
                    throw "未找到该 Proposal"
                }
                print("walletconectv2 approveProposal", Set((arguments["accounts"] as! [String]).map({$0})))
                try self.client?.approve(proposal: self.proposals[proposalId]!, accounts: Set((arguments["accounts"] as! [String]).map({$0})), completion: { res in
                    print("walletconectv2 client.approve", res)
                })
                self.proposals.removeValue(forKey: proposalId)
            case "response":
                if self.client == nil {
                    throw "尚未初始化"
                }
                guard let arguments = call.arguments as? [String: Any] else {
                    throw "传递参数异常"
                }
                let err_code = arguments["err_code"] as! Int
                if err_code  == 0 {
                    let response = JSONRPCResponse<AnyCodable>(id: arguments["id"] as! Int64, result: AnyCodable(arguments["data"] as! String))
                    self.client?.respond(topic: arguments["topic"] as! String, response: .response(response))
                } else {
                    self.client?.respond(topic: arguments["topic"] as! String, response: .error(JSONRPCErrorResponse.init(id: arguments["id"] as! Int64, error: JSONRPCErrorResponse.Error.init(code: err_code, message: arguments["err_msg"] as! String))))
                }
            case "getPlatformVersion":
                result("iOS " + UIDevice.current.systemVersion)
            default:
                result(FlutterMethodNotImplemented);
            }
        }
        catch {
            result(FlutterError(code: "0", message: "\(error)", details: nil))
        }
        print("walletconectv2 handle done", call.method, call.arguments)
    }
    
    public func didUpdate(sessionTopic: String, accounts: Set<String>) {
        print("walletconectv2 didUpdate", sessionTopic, accounts)
    }
    
    public func didReceive(sessionProposal: SessionProposal) {
        do {
            let proposalId = self.proposalId + 1
            self.proposals[proposalId] = sessionProposal
            self.channel?.invokeMethod("onProposal", arguments: [
                "proposalId": proposalId,
                "proposer": String(data: try JSONEncoder().encode(sessionProposal.proposer), encoding: .utf8),
                "permissions": [
                    "blockchains": Array(sessionProposal.permissions.blockchains),
                    "methods": Array(sessionProposal.permissions.methods),
                ]
            ])
        } catch {
            print("didReceive error", error)
        }
    }
    
    public func didReceive(sessionRequest: SessionRequest) {
        do {
            let sessions = self.client!.getSettledSessions()
            let sessionIndex = sessions.firstIndex(where: { s in
                s.topic == sessionRequest.topic
            })!
            self.channel?.invokeMethod("onRequest", arguments: [
                "proposer":String(data: try JSONEncoder().encode(sessions[sessionIndex].peer), encoding: .utf8),
                "request": String(data: try JSONEncoder().encode(sessionRequest), encoding: .utf8),
            ])
        } catch {
            print("didReceive error", error)
        }
    }
    
    public func didDelete(sessionTopic: String, reason: SessionType.Reason) {
        print("walletconectv2 didDelete", sessionTopic, reason)
    }
    
    public func didUpgrade(sessionTopic: String, permissions: SessionType.Permissions) {
        print("walletconectv2 didUpgrade", sessionTopic, permissions)
    }
    
    private func onInit(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if self.client != nil {
            throw "已初始化"
        }
        guard let arguments = call.arguments as? [String: Any] else {
            throw "传递参数异常"
        }
        
        let metadata = try JSONDecoder().decode(AppMetadata.self, from: (arguments["metadata"] as! String).data(using: .utf8)!)
        self.client = WalletConnectClient(metadata: metadata, projectId: arguments["projectId"] as! String, isController: arguments["isController"] as! Bool, relayHost: arguments["relayHost"] as! String)
        self.client!.delegate = self
        print("walletconectv2 oninit", metadata, arguments["isController"], arguments["relayHost"])
        result(nil)
    }
}
