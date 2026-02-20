import WatchConnectivity
import HealthKit
import CoreMotion

/**
 * EpilepsyCare AI - WatchOS Extension Bridge
 * Architecture: Senior SaMD Implementation
 * 
 * Responsibilities:
 * 1. HealthKit Query (HR + HRV)
 * 2. Fall Detection (CoreMotion)
 * 3. WCSession Communication
 */

class WatchSessionManager: NSObject, WCSessionDelegate, HKWorkoutSessionDelegate {
    
    static let shared = WatchSessionManager()
    private let session = WCSession.default
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        startMonitoring()
    }
    
    // MARK: - 1. Telemetry Loop
    func startMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // Setup Real-time Query for Heart Rate
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKAnchoredObjectQuery(type: hrType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deleted, anchor, error) in
            guard let newSamples = samples as? [HKQuantitySample] else { return }
            self.processHeartRate(newSamples)
        }
        query.updateHandler = { (query, samples, deleted, anchor, error) in
            guard let newSamples = samples as? [HKQuantitySample] else { return }
            self.processHeartRate(newSamples)
        }
        healthStore.execute(query)
        
        // Start Accelerometer for Fall Detection (High G-Force)
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let data = data else { return }
                self.detectFall(data.acceleration)
            }
        }
    }
    
    // MARK: - 2. Logic & Communication
    
    private func processHeartRate(_ samples: [HKQuantitySample]) {
        guard let sample = samples.last else { return }
        let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        
        // Send to Phone
        let payload: [String: Any] = ["heartRate": bpm, "timestamp": Date().timeIntervalSince1970]
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }
    
    private func detectFall(_ acceleration: CMAcceleration) {
        // Simple Vector Magnitude Calc: sqrt(x^2 + y^2 + z^2)
        let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        
        // Threshold: 3G (Impact)
        if magnitude > 3.0 {
            let payload: [String: Any] = ["fallDetected": true, "gForce": magnitude]
            session.sendMessage(payload, replyHandler: nil) { error in
                print("Error sending fall alert: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 3. Haptics (Received from Phone)
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let hapticType = message["triggerHaptic"] as? String {
            switch hapticType {
            case "WARNING":
                WKInterfaceDevice.current().play(.notification)
            case "CRITICAL":
                WKInterfaceDevice.current().play(.failure) // Distinctive feel
            case "RHYTHM":
                WKInterfaceDevice.current().play(.click) // 1Hz pacing
            default:
                break
            }
        }
    }
    
    // Boilerplate WCSession stubs...
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}