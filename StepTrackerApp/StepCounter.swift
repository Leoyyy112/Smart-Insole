import Foundation

class StepCounter: ObservableObject {
    @Published var stepCount: Int = 0
    @Published var distance: Double = 0
    @Published var caloriesBurned: Double = 0
    @Published var stepFrequency: Double = 0
    @Published var totalCaloriesBurned: Double = 0
    
    private var dataBuffer: [SensorData] = []
    private let windowSize = 50
    private let userHeight: Double
    private let userWeight: Double
    private let userAge: Int
    private let userGender: String
    private var lastStepTimestamp: Double = 0
    private let minStepInterval: Double = 0.4
    private let gravity: Double = 9.81
    private let gyroThreshold: Double = 0.1 // 陀螺仪阈值
    private let stepThresholdCount = 2 // 连续检测到步伐的次数阈值
    private var consecutiveSteps = 0 // 用于累计连续检测到的步数
    private var lastStepTime: Double = 0
    private var lastCalorieUpdateTime: Double = 0
    private let calorieUpdateInterval: Double = 30.0
    
    init(userHeight: Double, userWeight: Double, userAge: Int, userGender: String) {
        self.userHeight = userHeight
        self.userWeight = userWeight
        self.userAge = userAge
        self.userGender = userGender
    }
    
    func addSensorData(_ data: SensorData) {
        dataBuffer.append(data)
        if dataBuffer.count > windowSize {
            dataBuffer.removeFirst()
        }
        
        // 只有当数据缓冲区满了才进行计算
        if dataBuffer.count == windowSize {
            // 移除异常值
            dataBuffer = removeOutliers(dataBuffer)
            updateStepCount()
            updateDistance()
            updateCaloriesBurned()
            updateStepFrequency()
        }
    }
    
    private func removeOutliers(_ data: [SensorData]) -> [SensorData] {
        let accelXValues = data.map { $0.accelX }
        let accelYValues = data.map { $0.accelY }
        let accelZValues = data.map { $0.accelZ }
        
        let xLowerBound = accelXValues.quantile(0.01)
        let xUpperBound = accelXValues.quantile(0.99)
        let yLowerBound = accelYValues.quantile(0.01)
        let yUpperBound = accelYValues.quantile(0.99)
        let zLowerBound = accelZValues.quantile(0.01)
        let zUpperBound = accelZValues.quantile(0.99)
        
        return data.filter {
            $0.accelX > xLowerBound && $0.accelX < xUpperBound &&
            $0.accelY > yLowerBound && $0.accelY < yUpperBound &&
            $0.accelZ > zLowerBound && $0.accelZ < zUpperBound
        }
    }
    
    private func updateStepCount() {
            // 如果设备处于静止状态，则不计步
            if isDeviceStationary() {
                return
            }
            
            let accelMagnitudes = dataBuffer.map { sqrt(pow($0.accelX, 2) + pow($0.accelY, 2) + pow($0.accelZ - gravity, 2)) }
            print("Acceleration magnitudes: \(accelMagnitudes)")
            
            // 增大平滑窗口大小
            let smoothedMagnitudes = medianFilter(signal: accelMagnitudes, windowSize: 7)
            print("Smoothed magnitudes: \(smoothedMagnitudes)")
            
            // 双重阈值检测，初始较高阈值
            let initialThreshold = 2.2
            if smoothedMagnitudes.max() ?? 0 < initialThreshold {
                return
            }
            
            let detectedSteps = detectStepsUsingAdaptiveThreshold(signal: smoothedMagnitudes, threshold: 2.2, influence: 0.5)
            print("Detected steps: \(detectedSteps)")
        
            // 使用陀螺仪数据进一步过滤检测到的步伐
            let validSteps = filterStepsWithGyro(detectedSteps: detectedSteps)
                
            
            if validSteps > 0 && (dataBuffer.last?.timestamp ?? 0) - lastStepTime >= minStepInterval {
                        consecutiveSteps += 1
                        if consecutiveSteps >= stepThresholdCount {
                            stepCount += 1 // 每次只增加一步
                            lastStepTime = dataBuffer.last?.timestamp ?? 0
                            consecutiveSteps = 0
                        }
                    } else {
                        consecutiveSteps = 0
                    }
                }
    
    
    private func isDeviceStationary() -> Bool {
            let gyroMagnitudes = dataBuffer.map { sqrt(pow($0.gyroX, 2) + pow($0.gyroY, 2) + pow($0.gyroZ, 2)) }
            let maxGyroMagnitude = gyroMagnitudes.max() ?? 0.0
            
            return maxGyroMagnitude < gyroThreshold
        }
    
    
    private func medianFilter(signal: [Double], windowSize: Int = 6) -> [Double] {
        var result = [Double]()
        let halfWindowSize = windowSize / 2
        for i in 0..<signal.count {
            let start = max(i - halfWindowSize, 0)
            let end = min(i + halfWindowSize, signal.count - 1)
            let window = Array(signal[start...end])
            let median = window.sorted()[window.count / 2]
            result.append(median)
        }
        return result
    }
    
    private func detectStepsUsingAdaptiveThreshold(signal: [Double], threshold: Double = 2.2, influence: Double = 0.5) -> Int {
        let lag = max(1, min(30, signal.count / 2))  // 动态调整 lag 值，且至少为 1
        
        var steps = 0
        var avgFilter = Array(repeating: 0.0, count: signal.count)
        var stdFilter = Array(repeating: 0.0, count: signal.count)
        var filteredSignal = signal

        // 确保 lag 的合法性
        guard signal.count >= lag else {
            print("Error: Signal length is less than lag value.")
            return 0
        }

        // 初始化前 lag 个元素
        let initialSegment = signal[..<lag]
        avgFilter[lag - 1] = initialSegment.reduce(0, +) / Double(lag)
        stdFilter[lag - 1] = sqrt(initialSegment.map { pow($0 - avgFilter[lag - 1], 2) }.reduce(0, +) / Double(lag))

        for i in lag..<signal.count {
            if abs(signal[i] - avgFilter[i - 1]) > threshold * stdFilter[i - 1] {
                if signal[i] > avgFilter[i - 1] {
                    steps += 1
                }
                filteredSignal[i] = influence * signal[i] + (1 - influence) * filteredSignal[i - 1]
            } else {
                filteredSignal[i] = signal[i]
            }
            
            avgFilter[i] = filteredSignal[(i - lag + 1)...i].reduce(0, +) / Double(lag)
            stdFilter[i] = sqrt(filteredSignal[(i - lag + 1)...i].map { pow($0 - avgFilter[i], 2) }.reduce(0, +) / Double(lag))
        }
        
        return steps
    }

    // 新增的陀螺仪数据辅助过滤函数
    private func filterStepsWithGyro(detectedSteps: Int) -> Int {
        let gyroMagnitudes = dataBuffer.map { sqrt(pow($0.gyroX, 2) + pow($0.gyroY, 2) + pow($0.gyroZ, 2)) }
        
        // 设定一个陀螺仪阈值，过滤掉合成陀螺仪幅值较小的检测结果
        let gyroStepThreshold = 0.15
        let validSteps = gyroMagnitudes.filter { $0 > gyroStepThreshold }.count
        
        return min(detectedSteps, validSteps)
    }

    private func updateDistance() {
        let stepLength = userHeight * 0.415 / 100 // 转换为米
        distance = Double(stepCount) * stepLength / 1000 // 转换为千米
    }
    
    private func updateCaloriesBurned() {
            guard let currentTimestamp = dataBuffer.last?.timestamp else {
                        return
                    }
        
            // 如果是第一次更新，初始化 lastCalorieUpdateTime
            if lastCalorieUpdateTime == 0 {
                lastCalorieUpdateTime = currentTimestamp
                return
            }
        
            // 检查是否已经达到最小更新间隔
            if currentTimestamp - lastCalorieUpdateTime < calorieUpdateInterval {
                return
            }
            let durationInHours = (currentTimestamp - lastCalorieUpdateTime) / 3600.0 // 转换为小时
            // 确保计算时间间隔为正
            guard durationInHours > 0 else { return }
            // 调整每步的卡路里计算
            let caloriesPerStep = 0.05 // 每步约 0.05 Kcal，考虑步幅和运动强度
            let currentCaloriesBurned = Double(stepCount) * caloriesPerStep
            //let currentCaloriesBurned = caloriesPerHour * durationInHours
            
            totalCaloriesBurned += currentCaloriesBurned
            caloriesBurned = currentCaloriesBurned
            
            lastCalorieUpdateTime = currentTimestamp
        }
    

    private func getDynamicMET() -> Double {
            let gyroMagnitudes = dataBuffer.map { sqrt(pow($0.gyroX, 2) + pow($0.gyroY, 2) + pow($0.gyroZ, 2)) }
            let maxGyroMagnitude = gyroMagnitudes.max() ?? 0.0
            
            // 更精确的 MET 值计算
            if maxGyroMagnitude < 0.1 {
                return 1.0 // 静止
            } else if maxGyroMagnitude < 0.5 {
                return 2.0 // 缓慢行走
            } else if maxGyroMagnitude < 1.0 {
                return 3.0 // 正常行走
            } else if maxGyroMagnitude < 2.0 {
                return 4.0 // 快速行走
            } else {
                return 5.0 // 跑步
            }
        }





    private func updateStepFrequency() {
        guard let firstTimestamp = dataBuffer.first?.timestamp,
              let lastTimestamp = dataBuffer.last?.timestamp else {
            return
        }
        
        let durationInSeconds = lastTimestamp - firstTimestamp
        let durationInMinutes = durationInSeconds / 60.0 // 转换为分钟
        
        if durationInMinutes > 0 {
            stepFrequency = Double(stepCount) / durationInMinutes
        } else {
            stepFrequency = 0 // 避免除以零
        }
    }
}

// 扩展 Array，用于计算分位数
extension Array where Element: Comparable {
    func quantile(_ quantile: Double) -> Element {
        let sortedArray = self.sorted()
        let index = Int(Double(sortedArray.count - 1) * quantile)
        return sortedArray[index]
    }
}
