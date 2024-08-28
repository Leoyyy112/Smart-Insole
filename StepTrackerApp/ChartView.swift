import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var stepCounter: StepCounter
    let sensorData: SensorData?
    
    var body: some View {
        VStack {
            if let data = sensorData {
                Text("Latest Sensor Data")
                    .font(.headline)
                Text("AccelX: \(String(format: "%.2f", data.accelX))")
                Text("AccelY: \(String(format: "%.2f", data.accelY))")
                Text("AccelZ: \(String(format: "%.2f", data.accelZ))")
                Text("GyroX: \(String(format: "%.2f", data.gyroX))")
                Text("GyroY: \(String(format: "%.2f", data.gyroY))")
                Text("GyroZ: \(String(format: "%.2f", data.gyroZ))")
            }
            
            Chart {
                BarMark(
                    x: .value("Metric", "Steps"),
                    y: .value("Value", stepCounter.stepCount)
                )
                BarMark(
                    x: .value("Metric", "Distance (m)"),
                    y: .value("Value", stepCounter.distance * 1000)
                )
                BarMark(
                    x: .value("Metric", "Calories"),
                    y: .value("Value", stepCounter.caloriesBurned)
                )
            }
            .frame(height: 300)
            .padding()
            
            Text("Activity Summary")
                .font(.headline)
            Text("Steps: \(stepCounter.stepCount)")
            Text("Distance: \(String(format: "%.2f km", stepCounter.distance))")
            Text("Calories Burned: \(String(format: "%.2f kcal", stepCounter.caloriesBurned))")
            Text("Step Frequency: \(String(format: "%.2f steps/min", stepCounter.stepFrequency))")
        }
        .navigationTitle("Activity Chart")
    }
}
