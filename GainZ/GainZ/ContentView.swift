import SwiftUI
import UserNotifications
import Charts

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var description: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct WeeklyStats {
    var caloriesBurned: Int
    var totalTime: Int // in hours
    var exercises: Int
    var mostActiveDay: String
    var workoutStreak: Int
    var bodyMassIndex: Double
}

struct DailyProgress: Identifiable {
    let id = UUID()
    let date: Date
    var calories: Int
    var workoutDuration: Int // in minutes
    var notes: String
}

struct UserAccount {
    var username: String
    var email: String
    var password: String // In a real app, do NOT store plaintext passwords
}

// MARK: - App State

class FitnessData: ObservableObject {
    @Published var stats = WeeklyStats(caloriesBurned: 0, totalTime: 0, exercises: 0, mostActiveDay: "", workoutStreak: 0, bodyMassIndex: 0.0)
    @Published var dailyLogs: [DailyProgress] = []
    @Published var currentUser: UserAccount? = nil

    func logWorkout(calories: Int, duration: Int, notes: String) {
        let newLog = DailyProgress(date: Date(), calories: calories, workoutDuration: duration, notes: notes)
        dailyLogs.append(newLog)
        stats.caloriesBurned += calories
        stats.totalTime += duration / 60
        stats.exercises += 1
        stats.workoutStreak += 1
    }

    func resetStreak() {
        stats.workoutStreak = 0
    }

    func createAccount(username: String, email: String, password: String) {
        currentUser = UserAccount(username: username, email: email, password: password)
    }

    func signOut() {
        currentUser = nil
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notifications allowed")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func scheduleReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "GainZ Reminder"
        content.body = "It's time to work out"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule reminder: \(error.localizedDescription)")
            } else {
                print("Workout reminder scheduled at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
}

struct ContentView: View {
    @StateObject var fitnessData = FitnessData()
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .system
    @State private var showAuthView = true
    @State private var showSplash = true

    var body: some View {
        if showSplash {
            SplashScreen(isActive: $showSplash)
                .preferredColorScheme(selectedTheme.colorScheme)
        } else if showAuthView && fitnessData.currentUser == nil {
            AuthView(showAuthView: $showAuthView)
                .environmentObject(fitnessData)
                .preferredColorScheme(selectedTheme.colorScheme)
        } else {
            TabView {
                DashboardView(showAuthView: $showAuthView)
                    .environmentObject(fitnessData)
                    .tabItem {
                        Label("Dashboard", systemImage: "flame")
                    }
                HealthToolsView()
                    .environmentObject(fitnessData)
                    .tabItem {
                        Label("Health", systemImage: "heart")
                    }
                TrackerView()
                    .environmentObject(fitnessData)
                    .tabItem {
                        Label("Tracker", systemImage: "chart.bar")
                    }
            }
            .preferredColorScheme(selectedTheme.colorScheme)
            .onAppear {
                fitnessData.requestNotificationPermission()
            }
        }
    }
}

struct AuthView: View {
    @EnvironmentObject var fitnessData: FitnessData
    @Binding var showAuthView: Bool
    @State private var isLogin = true
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(isLogin ? "Log In" : "Create Account")) {
                    if !isLogin {
                        TextField("Username", text: $username)
                    }
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)

                    Button(isLogin ? "Log In" : "Create") {
                        if isLogin {
                            fitnessData.currentUser = UserAccount(username: "", email: email, password: password)
                        } else {
                            fitnessData.createAccount(username: username, email: email, password: password)
                        }
                        showAuthView = false
                    }

                    Button(isLogin ? "Don't have an account? Create one" : "Already have an account? Log In") {
                        isLogin.toggle()
                    }
                }
            }
            .navigationTitle("Welcome to GainZ")
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var fitnessData: FitnessData
    @Binding var showAuthView: Bool
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Hello,")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text(fitnessData.currentUser?.username.isEmpty == false ? fitnessData.currentUser!.username : "User")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                Spacer()
                Menu {
                    Button("Settings") {
                        showingSettings = true
                    }
                    Button("Sign Out") {
                        fitnessData.signOut()
                        showAuthView = true
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(fitnessData)
            }

            HStack(spacing: 20) {
                StatView(title: "cal burned", value: "\(fitnessData.stats.caloriesBurned)")
                StatView(title: "total time", value: "\(fitnessData.stats.totalTime)h")
                StatView(title: "exercises", value: "\(fitnessData.stats.exercises)")
            }
            .padding(.horizontal)

            DashboardChartView()
                .environmentObject(fitnessData)

            VStack(alignment: .leading) {
                Text("Most active: \(fitnessData.stats.mostActiveDay.isEmpty ? "N/A" : fitnessData.stats.mostActiveDay)")
                Text("Workout Streak: \(fitnessData.stats.workoutStreak) days")
                Text("BMI: \(String(format: "%.1f", fitnessData.stats.bodyMassIndex))")
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Daily Progress")
                    .font(.headline)
                    .padding(.horizontal)

                if fitnessData.dailyLogs.isEmpty {
                    Text("No workouts logged yet.")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
                    ForEach(fitnessData.dailyLogs.suffix(5).reversed()) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(log.calories) cal, \(log.workoutDuration) min")
                                .font(.body)
                            if !log.notes.isEmpty {
                                Text("Note: \(log.notes)")
                                    .italic()
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }

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

struct DashboardChartView: View {
    @EnvironmentObject var fitnessData: FitnessData

    struct StatItem: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
    }

    var body: some View {
        let data: [StatItem] = [
            StatItem(label: "Streak", value: Double(fitnessData.stats.workoutStreak)),
            StatItem(label: "BMI", value: fitnessData.stats.bodyMassIndex),
            StatItem(label: "Calories", value: Double(fitnessData.stats.caloriesBurned))
        ]

        Chart(data) { item in
            BarMark(
                x: .value("Metric", item.label),
                y: .value("Value", item.value)
            )
            .foregroundStyle(by: .value("Metric", item.label))
        }
        .frame(height: 200)
        .padding(.horizontal)
    }
}


struct HealthToolsView: View {
    @EnvironmentObject var fitnessData: FitnessData
    @State private var weight = ""
    @State private var height = ""
    @State private var dailyCalories = ""
    @State private var reminderTime = Date() // Updated

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("BMI Calculator")) {
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)

                    Button("Calculate BMI") {
                        if let w = Double(weight), let h = Double(height), h > 0 {
                            let heightInMeters = h / 100
                            let bmi = w / (heightInMeters * heightInMeters)
                            fitnessData.stats.bodyMassIndex = bmi
                        }
                    }
                }

                Section(header: Text("Calorie Counter")) {
                    TextField("Calories Consumed", text: $dailyCalories)
                        .keyboardType(.numberPad)

                    Button("Add to Burned") {
                        if let cal = Int(dailyCalories) {
                            fitnessData.stats.caloriesBurned += cal
                            dailyCalories = ""
                        }
                    }
                }

                Section(header: Text("Set Daily Reminder")) {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)

                    Button("Set Reminder") {
                        let calendar = Calendar.current
                        let hour = calendar.component(.hour, from: reminderTime)
                        let minute = calendar.component(.minute, from: reminderTime)
                        fitnessData.scheduleReminder(hour: hour, minute: minute)
                    }
                }
            }
            .navigationTitle("Health Tools")
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
                            Text("\(log.calories) cal, \(log.workoutDuration) min")
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


struct SettingsView: View {
    @EnvironmentObject var fitnessData: FitnessData
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .system
    @State private var newUsername = ""
    @State private var newPassword = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Account Info")) {
                    TextField("New Username", text: $newUsername)
                    SecureField("New Password", text: $newPassword)

                    Button("Save Changes") {
                        if !newUsername.isEmpty {
                            fitnessData.currentUser?.username = newUsername
                        }
                        if !newPassword.isEmpty {
                            fitnessData.currentUser?.password = newPassword
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.description).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            newUsername = fitnessData.currentUser?.username ?? ""
        }
    }
}

struct SplashScreen: View {
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Image("splashImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                Spacer()
                Text("Welcome to GainZ")
                    .font(.headline)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}
