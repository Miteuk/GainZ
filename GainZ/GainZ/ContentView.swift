import SwiftUI

// MARK: - Data Models

struct WeeklyStats {
    var kcalBurned: Int
    var totalTime: Int // in hours
    var exercises: Int
    var mostActiveDay: String
    var workoutStreak: Int
    var bodyMassIndex: Double
}

struct WorkoutProgram: Identifiable {
    let id = UUID()
    var title: String
    var coach: String
    var duration: Int // in minutes
    var imageName: String
}

struct DailyProgress: Identifiable {
    let id = UUID()
    let date: Date
    var calories: Int
    var workoutDuration: Int // in minutes
    var notes: String
}

// MARK: - App State

class FitnessData: ObservableObject {
    @Published var stats = WeeklyStats(kcalBurned: 2154, totalTime: 16, exercises: 107, mostActiveDay: "Thursday", workoutStreak: 5, bodyMassIndex: 22.5)
    @Published var dailyLogs: [DailyProgress] = []

    func logWorkout(calories: Int, duration: Int, notes: String) {
        let newLog = DailyProgress(date: Date(), calories: calories, workoutDuration: duration, notes: notes)
        dailyLogs.append(newLog)
        stats.kcalBurned += calories
        stats.totalTime += duration / 60
        stats.exercises += 1
        stats.workoutStreak += 1
    }

    func resetStreak() {
        stats.workoutStreak = 0
    }
}

// MARK: - Main Views

struct ContentView: View {
    @StateObject var fitnessData = FitnessData()

    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(fitnessData)
                .tabItem {
                    Label("Dashboard", systemImage: "flame")
                }
            ProgramsView()
                .tabItem {
                    Label("Programs", systemImage: "list.bullet")
                }
            TrackerView()
                .environmentObject(fitnessData)
                .tabItem {
                    Label("Tracker", systemImage: "chart.bar")
                }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var fitnessData: FitnessData

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Hello,")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Benjamin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                Spacer()
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            .padding(.horizontal)

            HStack(spacing: 20) {
                StatView(title: "kcal burnt", value: "\(fitnessData.stats.kcalBurned)")
                StatView(title: "total time", value: "\(fitnessData.stats.totalTime)h")
                StatView(title: "exercises", value: "\(fitnessData.stats.exercises)")
            }
            .padding(.horizontal)

            VStack(alignment: .leading) {
                Text("Most active: \(fitnessData.stats.mostActiveDay)")
                Text("Workout Streak: \(fitnessData.stats.workoutStreak) days")
                Text("BMI: \(String(format: "%.1f", fitnessData.stats.bodyMassIndex))")
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Text("Try celebrity training programs!")
                    .fontWeight(.medium)
                Spacer()
                Button("Let's try") {}
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }
}

struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct ProgramsView: View {
    let program = WorkoutProgram(title: "The Power Start", coach: "Kevin Hart", duration: 10, imageName: "kevin_hart")

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(program.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Text(program.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text("Coach: \(program.coach)")
                    .foregroundColor(.gray)

                Button(action: {}) {
                    Text("Start")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Programs")
            .padding()
        }
    }
}

struct TrackerView: View {
    @EnvironmentObject var fitnessData: FitnessData
    @State private var calories = ""
    @State private var duration = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Workout")) {
                    TextField("Calories Burned", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("Duration (min)", text: $duration)
                        .keyboardType(.numberPad)
                    TextField("Notes", text: $notes)

                    Button("Save") {
                        if let cal = Int(calories), let dur = Int(duration) {
                            fitnessData.logWorkout(calories: cal, duration: dur, notes: notes)
                            calories = ""
                            duration = ""
                            notes = ""
                        }
                    }
                }

                Section(header: Text("Daily Progress")) {
                    ForEach(fitnessData.dailyLogs) { log in
                        VStack(alignment: .leading) {
                            Text(log.date, style: .date)
                            Text("\(log.calories) kcal, \(log.workoutDuration) min")
                            if !log.notes.isEmpty {
                                Text(log.notes).italic()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tracker")
        }
    }
}

