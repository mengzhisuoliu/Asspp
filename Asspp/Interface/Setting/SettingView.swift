//
//  SettingView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct SettingView: View {
    @Environment(\.openURL) private var openURL
    @State private var vm = AppStore.this

    @State private var deviceIdTapCount = 0
    @State private var showDeviceIdWarning = false
    @State private var editingDeviceId = false
    @State private var deviceIdDraft = ""

    var body: some View {
        #if os(iOS)
            NavigationStack {
                formContent
            }
        #else
            NavigationStack {
                formContent
            }
        #endif
    }

    private var formContent: some View {
        FormOnTahoeList {
            Section {
                Toggle("Demo Mode", isOn: $vm.demoMode)
            } header: {
                Text("Demo Mode")
            } footer: {
                Text("By enabling this, all your accounts and sensitive information will be redacted.")
            }
            Section {
                Button("Delete All Downloads", role: .destructive) {
                    Downloads.this.removeAll()
                }
            } header: {
                Text("Downloads")
            } footer: {
                Text("Manage downloads.")
            }
            Section {
                Text(ProcessInfo.processInfo.hostName)
                    .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                if editingDeviceId {
                    TextField("Device GUID", text: $deviceIdDraft)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                    #if canImport(UIKit)
                        .textInputAutocapitalization(.never)
                    #endif
                    Button("Save") {
                        let trimmed = deviceIdDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        vm.deviceIdentifier = trimmed
                        ApplePackage.Configuration.deviceIdentifier = trimmed
                        editingDeviceId = false
                    }
                    Button("Cancel", role: .destructive) {
                        editingDeviceId = false
                    }
                } else {
                    Text(vm.deviceIdentifier)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                        .onTapGesture {
                            deviceIdTapCount += 1
                            if deviceIdTapCount >= 10 {
                                deviceIdTapCount = 0
                                showDeviceIdWarning = true
                            }
                        }
                }
                #if canImport(UIKit)
                    Button("Open Settings") {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    }
                #else
                    Button("Open Settings") {
                        openURL(URL(string: "x-apple.systempreferences:")!)
                    }
                #endif
            } header: {
                Text("Host Name")
            } footer: {
                Text("Grant local network permission to install apps and communicate with system services. If hostname is empty, open Settings to grant permission.")
            }
            .alert("Edit Device GUID", isPresented: $showDeviceIdWarning) {
                Button("Edit", role: .destructive) {
                    deviceIdDraft = vm.deviceIdentifier
                    editingDeviceId = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Changing the device GUID may cause all existing accounts to stop working. Apple limits the number of devices you can sign in with at once.")
            }

            #if canImport(UIKit)
                Section {
                    Button("Install Certificate") {
                        openURL(Installer.caURL)
                    }
                } header: {
                    Text("SSL")
                } footer: {
                    Text("On device installer requires your system to trust a self signed certificate. Tap the button to install it. After install, navigate to Settings > General > About > Certificate Trust Settings and enable full trust for the certificate.")
                }
            #endif

            #if canImport(AppKit) && !canImport(UIKit)
                Section {
                    Button("Show Certificate in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([Installer.ca])
                    }
                } header: {
                    Text("SSL")
                } footer: {
                    Text("On macOS, install certificates through System Keychain.")
                }
            #endif

            Section {
                NavigationLink("Logs") {
                    LogView()
                }
            } header: {
                Text("Diagnostics")
            } footer: {
                Text("View application logs for troubleshooting.")
            }

            Section {
                Button("@Lakr233") {
                    openURL(URL(string: "https://twitter.com/Lakr233")!)
                }
                Button("Buy me a coffee! ☕️") {
                    openURL(URL(string: "https://github.com/sponsors/Lakr233/")!)
                }
                Button("Feedback & Contact") {
                    openURL(URL(string: "https://github.com/Lakr233/Asspp")!)
                }
            } header: {
                Text("About")
            } footer: {
                Text("Hope this app helps you!")
            }
            Section {
                Button("Reset", role: .destructive) {
                    try? FileManager.default.removeItem(at: documentsDirectory)
                    try? FileManager.default.removeItem(at: temporaryDirectory)
                    #if canImport(UIKit)
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    #endif
                    #if canImport(AppKit) && !canImport(UIKit)
                        NSApp.terminate(nil)
                    #endif
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1))
                        exit(0)
                    }
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("This will reset all your settings.")
            }
        }
        .navigationTitle("Settings")
    }
}
