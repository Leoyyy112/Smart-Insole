import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var weekStreakViewModel = WeekStreakViewModel()
    @State private var isDeviceConnected: Bool = false
    @State private var painLevel: Double = 5.0

    var body: some View {
        NavigationView {
            ZStack {
                if isDeviceConnected {
                    // 连接状态下的背景颜色
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                } else {
                    // 未连接状态下的背景图片
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                }

                VStack(spacing: 30) {
                    if bluetoothManager.isConnected {
                        WeekStreakView(viewModel: weekStreakViewModel)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.yellow, lineWidth: 15)
                                .frame(width: 210, height: 210)

                            VStack {
                                Image(systemName: "figure.walk")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.green)
                                Text("\(bluetoothManager.stepCounter.stepCount)")
                                    .font(.system(size: 72, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Steps")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack(spacing: 50) {
                            VStack(spacing: 5) {
                                Image(systemName: "flame.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.orange)
                                Text("\(Int(bluetoothManager.stepCounter.totalCaloriesBurned))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Cal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            VStack(spacing: 5) {
                                Image(systemName: "mappin.and.ellipse")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)
                                Text(String(format: "%.2f", bluetoothManager.stepCounter.distance))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                Text("mile")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        
                        PainLevelView(painLevel: $painLevel)

                        Button(action: {
                            bluetoothManager.disconnect()
                            isDeviceConnected = false
                        }) {
                            Text("Disconnect Device")
                                .font(.system(size: 18, weight: .semibold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .shadow(radius: 5)
                    } else {
                        Spacer()

                        Button(action: {
                            bluetoothManager.connect()
                            isDeviceConnected = true
                        }) {
                            Text("Connect")
                                .font(.system(size: 18, weight: .semibold))
                                .padding()
                                .frame(width: 180, height: 180)
                                .background(Color.yellow)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .shadow(radius: 5)

                        Spacer()
                    }
                }
                .padding()
            }
            .onAppear {
                bluetoothManager.checkBluetoothState()
            }
        }
    }
}
