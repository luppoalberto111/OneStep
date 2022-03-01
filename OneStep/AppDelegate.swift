import Foundation
import UIKit
import BackgroundTasks
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.oneStep.refreshTimer", using: .main) { task in
            NotificationCenter.default.post(.init(name: .endFetching))
            task.setTaskCompleted(success: true)
        }
    }
    
    func sceneChanged(scenePhase: ScenePhase) {
        guard scenePhase == .background else { return }
        let task = BGAppRefreshTaskRequest(identifier: "com.oneStep.refreshTimer")
        task.earliestBeginDate = Date(timeIntervalSinceNow: Constants.timeout)
        try? BGTaskScheduler.shared.submit(task)
    }
}
