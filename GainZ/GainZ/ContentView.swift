//
//  ContentView.swift
//  GainZ
//
//  Created by Tim Kue on 3/23/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Welcome to GainZ")
                    .font(.largeTitle.bold())
                    .padding(.top)

                // 🔗 Navigation to ReminderScreen
                NavigationLink(destination: ReminderScreen()) {
                    Text("View Reminders")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // 🗂 Existing List of Items
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                        } label: {
                            Text(item.timestamp!, formatter: itemFormatter)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Home")
        }
    }


    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


struct ReminderScreen: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReminderEntity.date, ascending: true)],
        animation: .default)
    private var reminders: FetchedResults<ReminderEntity>

    @State private var showingAddReminder = false
    @State private var editingReminder: ReminderEntity? = nil
    @State private var username: String = "Benjamin" // Replace with actual user logic

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Profile header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello,")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        Text(username)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                // Stats card
                HStack(spacing: 20) {
                    StatCard(title: "2,154", subtitle: "kcal burnt", icon: "flame.fill", color: .orange)
                    StatCard(title: "16h", subtitle: "total time", icon: "clock.fill", color: .green)
                    StatCard(title: "107", subtitle: "exercises", icon: "figure.walk", color: .blue)
                }
                .padding(.horizontal)

                // Reminders Section
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reminders")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ForEach(reminders) { reminder in
                            Button(action: {
                                editingReminder = reminder
                                showingAddReminder = true
                            }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(reminder.title ?? "Untitled")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)

                                    if let date = reminder.date {
                                        Text(date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(20)
                                .shadow(radius: 4)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
            }

            // Floating Add Button
            Button(action: {
                editingReminder = nil
                showingAddReminder = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.pink)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddReminder) {
            AddEditReminderView(reminder: $editingReminder)
        }
    }

    private func deleteReminder(at offsets: IndexSet) {
        for index in offsets {
            let reminder = reminders[index]
            viewContext.delete(reminder)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error deleting reminder: \(error.localizedDescription)")
        }
    }
}

struct StatCard: View {
    var title: String
    var subtitle: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .background(color.opacity(0.8))
                .clipShape(Circle())

            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct AddEditReminderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Binding var reminder: ReminderEntity?

    @State private var title: String = ""
    @State private var date: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder Details")) {
                    TextField("Enter reminder name", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    DatePicker("Select Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
            }
            .navigationTitle(reminder == nil ? "New Reminder" : "Edit Reminder")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let existingReminder = reminder {
                            existingReminder.title = title
                            existingReminder.date = date
                        } else {
                            let newReminder = ReminderEntity(context: viewContext)
                            newReminder.id = UUID()
                            newReminder.title = title
                            newReminder.date = date
                        }

                        do {
                            try viewContext.save()
                            dismiss()
                        } catch {
                            print("Error saving reminder: \(error.localizedDescription)")
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let reminder = reminder {
                    title = reminder.title ?? ""
                    date = reminder.date ?? Date()
                }
            }
        }
    }
}

#Preview {
    ReminderScreen()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

