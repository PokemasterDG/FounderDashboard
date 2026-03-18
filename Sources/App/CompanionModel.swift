import Foundation
import Observation

#if os(iOS)
@MainActor
@Observable
final class CompanionModel {
    private static let completedChecklistDefaultsKey = "FounderDashboard.completedLaunchChecklistTaskIDs"
    private static let cashRealityDefaultsKey = "FounderDashboard.launchCashReality"
    private static let siteStatusesDefaultsKey = "FounderDashboard.sitePipelineStatuses"

    var funding: FundingSnapshot
    let launchChecklistTasks: [LaunchChecklistTask]
    var isHydratingSnapshot = false

    var completedLaunchChecklistTaskIDs: Set<String>
    var sitePipelineStatuses: [String: SitePipelineStatus] {
        didSet {
            persistSitePipelineStatuses()
        }
    }
    var launchCashReality: LaunchCashReality {
        didSet {
            persistLaunchCashReality()
        }
    }

    var completedLaunchChecklistCount: Int {
        launchChecklistTasks.filter { completedLaunchChecklistTaskIDs.contains($0.id) }.count
    }

    var nextLaunchChecklistTask: LaunchChecklistTask? {
        launchChecklistTasks.first { !completedLaunchChecklistTaskIDs.contains($0.id) }
    }

    init(snapshot: PlanningSnapshot = .companionFallback) {
        self.funding = snapshot.funding
        self.launchChecklistTasks = LaunchChecklistTask.starterTasks
        self.completedLaunchChecklistTaskIDs = Set(
            UserDefaults.standard.stringArray(forKey: Self.completedChecklistDefaultsKey) ?? []
        )
        self.sitePipelineStatuses = Self.loadSitePipelineStatuses()
        self.launchCashReality = Self.loadLaunchCashReality()
    }

    func hydrateSnapshotIfNeeded() {
        guard !isHydratingSnapshot, funding.leadSite == PlanningSnapshot.companionFallback.funding.leadSite else {
            return
        }

        isHydratingSnapshot = true

        Task.detached(priority: .userInitiated) {
            let snapshot = (try? PlanningSnapshotLoader.load()) ?? .companionFallback

            await MainActor.run {
                self.funding = snapshot.funding
                self.isHydratingSnapshot = false
            }
        }
    }

    func toggleLaunchChecklistTask(_ task: LaunchChecklistTask) {
        if completedLaunchChecklistTaskIDs.contains(task.id) {
            completedLaunchChecklistTaskIDs.remove(task.id)
        } else {
            completedLaunchChecklistTaskIDs.insert(task.id)
        }

        UserDefaults.standard.set(
            Array(completedLaunchChecklistTaskIDs).sorted(),
            forKey: Self.completedChecklistDefaultsKey
        )
    }

    func sitePipelineStatus(for candidate: SiteCandidate) -> SitePipelineStatus {
        sitePipelineStatuses[candidate.name] ?? .active
    }

    func setSitePipelineStatus(_ status: SitePipelineStatus, for candidate: SiteCandidate) {
        sitePipelineStatuses[candidate.name] = status
    }

    private static func loadLaunchCashReality() -> LaunchCashReality {
        guard let data = UserDefaults.standard.data(forKey: cashRealityDefaultsKey),
              let decoded = try? JSONDecoder().decode(LaunchCashReality.self, from: data) else {
            return .empty
        }

        return decoded
    }

    private func persistLaunchCashReality() {
        guard let data = try? JSONEncoder().encode(launchCashReality) else {
            return
        }

        UserDefaults.standard.set(data, forKey: Self.cashRealityDefaultsKey)
    }

    private static func loadSitePipelineStatuses() -> [String: SitePipelineStatus] {
        guard let data = UserDefaults.standard.data(forKey: siteStatusesDefaultsKey),
              let decoded = try? JSONDecoder().decode([String: SitePipelineStatus].self, from: data) else {
            return [:]
        }

        return decoded
    }

    private func persistSitePipelineStatuses() {
        guard let data = try? JSONEncoder().encode(sitePipelineStatuses) else {
            return
        }

        UserDefaults.standard.set(data, forKey: Self.siteStatusesDefaultsKey)
    }
}

private extension PlanningSnapshot {
    static let companionFallback = PlanningSnapshot(
        generatedOn: "Unavailable",
        deckedBuilder: DeckedBuilderSnapshot(
            activeSubscribers: 0,
            appleProceedsTrailing12: 0,
            appleProceedsTrailing3: 0,
            appCashAvailable: 0,
            cashAvailableForStore: 0,
            baselineMonthlyOpsCost: 0,
            usSubscriberShare: 0,
            sixMonthSubscribers: 0,
            oneMonthSubscribers: 0,
            legacyLifetimeDownloads: 0,
            legacyIOSActiveDevices30DayAverage: 0,
            legacyIOSActiveDevices90DayAverage: 0,
            targetMilestone: "Load planning snapshot",
            androidRevenueLow: 0,
            androidRevenueHigh: 0,
            notes: ["Planning snapshot failed to load."],
            revenueSeries: []
        ),
        funding: FundingSnapshot(
            baseCashNeedLow: 0,
            baseCashNeedHigh: 0,
            strongFloorCash: 0,
            targetCash: 0,
            saferCash: 0,
            liquidationTarget: 0,
            founderCashLow: 0,
            founderCashHigh: 0,
            outsideCapitalLow: 0,
            outsideCapitalHigh: 0,
            retainedInventoryLow: 0,
            retainedInventoryHigh: 0,
            leadSite: "Unavailable",
            secondSite: "Unavailable",
            summary: "Planning snapshot failed to load.",
            notes: ["Load the bundled planning snapshot again from the Mac app project."],
            siteCandidates: [],
            scenarios: []
        ),
        documents: [],
        sources: []
    )
}
#endif
