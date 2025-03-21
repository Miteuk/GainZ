//
//  ViewController.swift
//  GainZ
//
//  Created by Tim Kue on 3/17/25.
//

import UIKit

struct Reminder {
    var time: Date
    var workoutType: String
    var isEnabled: Bool
}

class RemindersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var reminders: [Reminder] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reminders"
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func addReminderTapped(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addVC = storyboard.instantiateViewController(identifier: "AddReminderViewController") as? AddReminderViewController {
            addVC.delegate = self
            navigationController?.pushViewController(addVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath)
        let reminder = reminders[indexPath.row]
        cell.textLabel?.text = reminder.workoutType
        cell.detailTextLabel?.text = formattedDate(reminder.time)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            reminders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

extension RemindersViewController: AddReminderDelegate {
    func didAddReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        tableView.reloadData()
    }
}

protocol AddReminderDelegate: AnyObject {
    func didAddReminder(_ reminder: Reminder)
}

class AddReminderViewController: UIViewController {
    
    @IBOutlet weak var workoutTypeTextField: UITextField!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    weak var delegate: AddReminderDelegate?
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        guard let workoutType = workoutTypeTextField.text, !workoutType.isEmpty else { return }
        let newReminder = Reminder(time: timePicker.date, workoutType: workoutType, isEnabled: true)
        delegate?.didAddReminder(newReminder)
        navigationController?.popViewController(animated: true)
    }
}

