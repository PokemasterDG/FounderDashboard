import Foundation
import AppKit

enum DocumentOpening {
    static func open(_ document: PlanningDocument) {
        NSWorkspace.shared.open(document.url)
    }

    static func reveal(_ document: PlanningDocument) {
        NSWorkspace.shared.activateFileViewerSelecting([document.url])
    }
}
