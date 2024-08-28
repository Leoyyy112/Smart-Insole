
import Foundation
import CoreMotion

class StepTracker: ObservableObject {
    @Published var stepCount: Int = 1000
    @Published var distance: Double = 10000.0
    @Published var calories: Double = 550.0
    
    private let pedometer = CMPedometer()
    
    func startTracking() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
                guard let data = pedometerData, error == nil else { return }
                
                DispatchQueue.main.async {
                    self?.stepCount = data.numberOfSteps.intValue
                    self?.distance = data.distance?.doubleValue ?? 0.0
                    self?.calories = Double(self?.stepCount ?? 0) * 0.05 // 简单估算
                }
            }
        }
    }
}
