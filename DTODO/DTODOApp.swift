//  Created by Denis Malykh on 19.04.2021.

import SwiftUI

@main
struct DTODOApp: App {
    @Environment(\.scenePhase) private var phase

    var repository = Repository()
    var configStore = ConfigurationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(repository)
                .environmentObject(configStore)
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .active:
                break
            case .inactive, .background:
                repository.saveToDisk()
                configStore.configuration.save()
            @unknown default:
                break
            }
        }
    }
}
