import WatchConnectivity
import Combine

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionManager()
    
    private override init() {
        super.init()
        print("WatchSessionManager: init (lazy)")
    }
    
    func activate() {
        print("WatchSessionManager: activate called")
        if WCSession.isSupported() {
            print("WatchSessionManager: WCSession is supported, activating...")
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            print("WatchSessionManager: WCSession NOT supported")
        }
    }
    
    func sendHealthData(_ data: HealthData) {
        // Only try to send if we are active/reachable or want to transferUserInfo
        
        guard WCSession.default.isReachable else {
            // Fallback to transferUserInfo for background transfer
            if let encodedData = try? JSONEncoder().encode(data),
               let jsonDict = try? JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any] {
                WCSession.default.transferUserInfo(jsonDict)
            }
            return
        }
        
        if let encodedData = try? JSONEncoder().encode(data),
           let jsonDict = try? JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any] {
            WCSession.default.sendMessage(jsonDict, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation completion
        print("WatchSessionManager: activationDidCompleteWith state: \(activationState.rawValue)")
    }
    
    // Required WCSessionDelegate methods
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle received messages
    }
}
