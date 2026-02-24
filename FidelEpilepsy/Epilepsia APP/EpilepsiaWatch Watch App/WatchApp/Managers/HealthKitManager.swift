import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var currentHeartRate: Double = 0.0
    @Published var currentHRV: Double = 0.0
    @Published var isOnWrist: Bool = true // Watch detection mock
    
    private var simulationTimer: AnyCancellable?
    
    func requestAuthorization() {
        print("HealthKitManager: requesting authorization")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKitManager: Health data not available")
            return
        }
        
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            print("HealthKitManager: authorization completed. Success: \(success), Error: \(String(describing: error))")
        }
    }
    
    func startMonitoring() {
        print("HealthKitManager: startMonitoring (Mock Mode)")
        // For the sake of this mock implementation, we simulate real-time sensor data
        startSimulation()
    }
    
    private func startSimulation() {
        // Simulate reading heart rate every 3 seconds
        simulationTimer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isOnWrist {
                    // Fluctuate heart rate slightly
                    let baseHR = 72.0
                    let fluctuation = Double.random(in: -5.0...15.0)
                    self.currentHeartRate = baseHR + fluctuation
                    
                    // Update HRV occasionally
                    if Int.random(in: 1...5) == 1 {
                        self.currentHRV = Double.random(in: 40.0...80.0)
                    }
                } else {
                    self.currentHeartRate = 0.0
                }
            }
    }
    
    func toggleWristDetection() {
        isOnWrist.toggle()
    }
    
    // Existing functions kept for reference/future integration
    private func readHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            self.sendData(hr: heartRate, hrv: nil)
        }
        
        healthStore.execute(query)
    }
    
    private func readHRV() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            self.sendData(hr: nil, hrv: hrv)
        }
        
        healthStore.execute(query)
    }
    
    private func sendData(hr: Double?, hrv: Double?) {
        DispatchQueue.main.async {
            if let hr = hr {
                self.currentHeartRate = hr
            }
            if let hrv = hrv {
                self.currentHRV = hrv
            }
        }
        
        // In a real app, you would probably want to combine these or send them as part of a larger object.
        // For simplicity, we are sending them if available.
        // Also need to handle timestamp and aggregating HR/HRV together if possible.
        
        if let hr = hr {
             let data = HealthData(heartRate: hr, hrv: hrv ?? 0.0, timestamp: Date())
             WatchSessionManager.shared.sendHealthData(data)
        }
    }
}
