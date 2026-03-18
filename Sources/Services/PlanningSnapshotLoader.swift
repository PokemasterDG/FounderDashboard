import Foundation

enum PlanningSnapshotLoader {
    static func load() throws -> PlanningSnapshot {
        guard let url = Bundle.main.url(forResource: "planning_snapshot", withExtension: "json") else {
            throw SnapshotLoadingError.missingResource
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PlanningSnapshot.self, from: data)
    }
}

enum SnapshotLoadingError: LocalizedError {
    case missingResource

    var errorDescription: String? {
        switch self {
        case .missingResource:
            "The bundled planning snapshot could not be found."
        }
    }
}
