//
//  GitHubReleaseUpdateChecker.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import Foundation

protocol UpdateChecking {
    func checkForUpdates()
}

struct GitHubReleaseUpdateConfiguration {
    let owner: String
    let repository: String

    static let `default` = GitHubReleaseUpdateConfiguration(
        owner: "waruhachi",
        repository: "BatteryBuddyReborn"
    )

    static func current(bundle: Bundle = .main)
        -> GitHubReleaseUpdateConfiguration
    {
        guard
            let owner = bundle.object(
                forInfoDictionaryKey: "BatteryBuddyGitHubOwner"
            ) as? String,
            let repository = bundle.object(
                forInfoDictionaryKey: "BatteryBuddyGitHubRepository"
            ) as? String,
            !owner.isEmpty,
            !repository.isEmpty
        else {
            return .default
        }

        return GitHubReleaseUpdateConfiguration(
            owner: owner,
            repository: repository
        )
    }

    var latestReleaseURL: URL {
        URL(
            string:
                "https://api.github.com/repos/\(owner)/\(repository)/releases/latest"
        )!
    }
}

@MainActor
final class GitHubReleaseUpdateChecker: NSObject, UpdateChecking {
    private struct ReleasePayload: Decodable {
        let tagName: String
        let htmlURL: URL
        let name: String?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case name
        }
    }

    func checkForUpdates() {
        Task {
            await performCheck(
                configuration: GitHubReleaseUpdateConfiguration.current()
            )
        }
    }

    private func performCheck(configuration: GitHubReleaseUpdateConfiguration)
        async
    {
        do {
            let release = try await fetchLatestRelease(using: configuration)
            let currentVersion = normalizedVersionString(
                Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                    as? String
            )
            let latestVersion = normalizedVersionString(release.tagName)

            if latestVersion.compare(currentVersion, options: .numeric)
                == .orderedDescending
            {
                presentUpdateAvailableAlert(release: release)
            } else {
                presentAlert(
                    title: "BatteryBuddy Is Up to Date",
                    message:
                        "You’re running version \(currentVersion), which is the latest available release."
                )
            }
        } catch {
            presentAlert(
                title: "Unable to Check for Updates",
                message: error.localizedDescription
            )
        }
    }

    private func fetchLatestRelease(
        using configuration: GitHubReleaseUpdateConfiguration
    ) async throws -> ReleasePayload {
        let (data, response) = try await URLSession.shared.data(
            from: configuration.latestReleaseURL
        )
        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw UpdateError.invalidServerResponse
        }

        return try JSONDecoder().decode(ReleasePayload.self, from: data)
    }

    private func presentUpdateAvailableAlert(release: ReleasePayload) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        let displayVersion =
            release.name?.isEmpty == false ? release.name! : release.tagName
        alert.informativeText =
            "\(displayVersion) is available to download from GitHub Releases."
        alert.addButton(withTitle: "Open Release")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(release.htmlURL)
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func normalizedVersionString(_ string: String?) -> String {
        guard let string else { return "0" }
        return string.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }
}

private enum UpdateError: LocalizedError {
    case invalidServerResponse

    var errorDescription: String? {
        switch self {
        case .invalidServerResponse:
            return "GitHub did not return a valid latest release response."
        }
    }
}
