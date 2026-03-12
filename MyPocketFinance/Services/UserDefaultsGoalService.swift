import Foundation

protocol PersistentGoalService: GoalService {
    func saveGoals(_ goals: [Goal])
}

final class UserDefaultsGoalService: PersistentGoalService {
    private let storageKey = "goals_storage_key"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchGoals() -> [Goal] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let goals = try decoder.decode([Goal].self, from: data)
            return goals
        } catch {
            return []
        }
    }

    func saveGoals(_ goals: [Goal]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(goals)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Ignore encoding errors for now.
        }
    }
}

