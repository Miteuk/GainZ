import SwiftUI

struct ContentView: View {
    // BMI Tracker
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var bmi: Double? = nil
    @State private var bmiError: String = ""

    // Calorie Tracker
    @State private var caloriesConsumed: String = ""
    @State private var caloriesBurned: String = ""
    @State private var netCalories: Int? = nil
    @State private var calorieError: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - BMI Tracker Section
                    Group {
                        Text("Body Mass Tracker")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Enter weight in kg", text: $weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Enter height in meters", text: $height)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button(action: calculateBMI) {
                            Text("Calculate BMI")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        if let bmi = bmi {
                            Text("Your BMI is: \(String(format: "%.2f", bmi))")
                                .font(.headline)
                        }

                        if !bmiError.isEmpty {
                            Text(bmiError)
                                .foregroundColor(.red)
                        }
                    }

                    Divider()

                    // MARK: - Calorie Tracker Section
                    Group {
                        Text("Calorie Counter")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Calories Consumed", text: $caloriesConsumed)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Calories Burned", text: $caloriesBurned)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button(action: calculateCalories) {
                            Text("Calculate Net Calories")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        if let net = netCalories {
                            Text("Net Calories: \(net) kcal")
                                .font(.headline)
                        }

                        if !calorieError.isEmpty {
                            Text(calorieError)
                                .foregroundColor(.red)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("GainZ Tracker")
        }
    }

    // MARK: - BMI Calculation Logic
    private func calculateBMI() {
        guard let w = Double(weight), let h = Double(height), w > 0, h > 0 else {
            bmiError = "Please enter valid positive numbers."
            bmi = nil
            return
        }

        bmi = w / (h * h)
        bmiError = ""
    }

    // MARK: - Calorie Calculation Logic
    private func calculateCalories() {
        guard let consumed = Int(caloriesConsumed),
              let burned = Int(caloriesBurned),
              consumed >= 0, burned >= 0 else {
            calorieError = "Please enter valid numbers for calories."
            netCalories = nil
            return
        }

        netCalories = consumed - burned
        calorieError = ""
    }
}
