import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        print("ExtensionDelegate: applicationDidFinishLaunching")
        // Initialize WatchSessionManager early
        WatchSessionManager.shared.activate()
        
        // Schedule the first background refresh
        // scheduleBackgroundRefresh()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Handle background refresh
                HealthKitManager.shared.startMonitoring()
                
                // Schedule the next refresh
                scheduleBackgroundRefresh()
                
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func scheduleBackgroundRefresh() {
        let preferredDate = Date(timeIntervalSinceNow: 10 * 60) // 10 minutes
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: nil) { error in
            if let error = error {
                print("Error scheduling background refresh: \(error.localizedDescription)")
            }
        }
    }
}
