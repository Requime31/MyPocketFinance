import Foundation

protocol GoalService {
    func fetchGoals() -> [Goal]
}

extension Notification.Name {
    static let goalsDidChange = Notification.Name("goalsDidChange")
}


