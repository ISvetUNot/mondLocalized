//
//  SettingsView.swift
//  mondL
//
//  Created by ruter on 18.07.26.
//

import SwiftUI
import PartyUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var state: AppState
    
    @AppStorage("method") private var method: String = "worse_query"
    @AppStorage("ka_on") private var ka_on = true
    @AppStorage("token") private var token: String = ""
    @AppStorage("dismiss_after_import") private var dismiss_after_import = false
    @AppStorage("atomic_write") private var atomic_write = true
    @AppStorage("ignore_failure") private var ignore_failure = false
    
    @State private var show_confirm: Bool = false
    @State private var show_language_picker: Bool = false
    @ObservedObject private var language_manager = LanguageManager.shared
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if let url = URL(string: "https://github.com/rooootdev/mond"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                               let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                               let files = primary["CFBundleIconFiles"] as? [String],
                               let icon = files.last,
                               let img = UIImage(named: icon) {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                                     ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                                     ?? NSLocalizedString("unknown_app", tableName: "SettingsView", comment: ""))
                                .font(.headline)
                                
                                Text("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tertiary)
                                .imageScale(.small)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    Picker(NSLocalizedString("method", tableName: "SettingsView", comment: ""), selection: $method) {
                        Text("worse_query").tag("worse_query")
                        Text("bad_query").tag("bad_query")
                    }
                    .pickerStyle(.segmented)

                    Button {
                        grant_all(state: state)
                    } label: {
                        Text(NSLocalizedString("run_exploit", tableName: "SettingsView", comment: ""))
                    }
                } header: {
                    Label(NSLocalizedString("exploit", tableName: "SettingsView", comment: ""), systemImage: "wrench.and.screwdriver")
                }
                
                Section {
                    TextField(NSLocalizedString("sandbox_extension_token", tableName: "SettingsView", comment: ""), text: $token)
                    .contextMenu {
                        Text("\(NSLocalizedString("token_class", tableName: "SettingsView", comment: "")) \(token.split(separator: ";").first { $0.contains("com.apple") }.map(String.init) ?? "N/A")")
                        Text("\(NSLocalizedString("token_path", tableName: "SettingsView", comment: "")) \(token.split(separator: ";").last.map(String.init) ?? "N/A")")
                        
                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Label(NSLocalizedString("copy_token", tableName: "SettingsView", comment: ""), systemImage: "doc.on.doc")
                        }
                    }
                    .lineLimit(1)
                    
                    Button {
                        token = sandbox_extension_issue_file(path: TweakPaths.gestalt_dir) ?? NSLocalizedString("failed_to_get_token", tableName: "SettingsView", comment: "")
                    } label: {
                        Text(NSLocalizedString("generate_token", tableName: "SettingsView", comment: ""))
                    }
                    .disabled(!state.exploit_succeeded)
                } header: {
                    Label(NSLocalizedString("token", tableName: "SettingsView", comment: ""), systemImage: "key")
                } footer: {
                    if !token.isEmpty && token != NSLocalizedString("failed_to_get_token", tableName: "SettingsView", comment: "") {
                        if valid {
                            Text(NSLocalizedString("sandbox_token_valid", tableName: "SettingsView", comment: ""))
                        } else {
                            Text(NSLocalizedString("sandbox_token_invalid", tableName: "SettingsView", comment: ""))
                        }
                    }
                    
                    if !state.exploit_succeeded {
                        Text(NSLocalizedString("exploit_failed_version", tableName: "SettingsView", comment: ""))
                    }
                }
                
                Section {
                    PlainToggle(text: NSLocalizedString("keep_alive", tableName: "SettingsView", comment: ""), infoType: .info, infoMessage: NSLocalizedString("keep_alive_info", tableName: "SettingsView", comment: ""), isOn: $ka_on)
                        .onChange(of: ka_on) { _, enabled in
                            if enabled {
                                keep_alive()
                            } else {
                                let_die()
                            }
                        }

                    PlainToggle(text: NSLocalizedString("dismiss_after_importing", tableName: "SettingsView", comment: ""), infoType: .info, infoMessage: NSLocalizedString("dismiss_after_importing_info", tableName: "SettingsView", comment: ""), isOn: $dismiss_after_import)

                    PlainToggle(text: NSLocalizedString("persist_after_reboot", tableName: "SettingsView", comment: ""), infoType: .info, infoMessage: NSLocalizedString("persist_after_reboot_info", tableName: "SettingsView", comment: ""), isOn: $atomic_write)
                    
                    PlainToggle(text: NSLocalizedString("ignore_exploit_failure", tableName: "SettingsView", comment: ""), infoType: .info, infoMessage: NSLocalizedString("ignore_exploit_failure_info", tableName: "SettingsView", comment: ""), isOn: $ignore_failure)
                } header: {
                    Label(NSLocalizedString("settings", tableName: "SettingsView", comment: ""), systemImage: "gear")
                }
                
                Section {
                    Button {
                        show_confirm = true
                    } label: {
                        Text(NSLocalizedString("respring", comment: ""))
                    }
                } header: {
                    Label(NSLocalizedString("tools", tableName: "SettingsView", comment: ""), systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(try! AttributedString(markdown: NSLocalizedString("respring_method_credits", tableName: "SettingsView", comment: "")))
                }
                
                Section {
                    CreditsRow(name: "roooot", role: NSLocalizedString("credit_main_developer", tableName: "SettingsView", comment: ""), profile: URL(string: "https://github.com/rooootdev")!)
                    CreditsRow(name: "forcequit", role: NSLocalizedString("credit_bad_worse_query_exploit", tableName: "SettingsView", comment: ""), profile: URL(string: "https://github.com/forcequitOS")!)
                    CreditsRow(name: "johnny", role: NSLocalizedString("credit_mcm_bug_class", tableName: "SettingsView", comment: ""), profile: URL(string: "https://github.com/0xjohnnydev")!)
                    CreditsRow(name: "jailbreak.party", role: NSLocalizedString("credit_partyui_gestaltview", tableName: "SettingsView", comment: ""), profile: URL(string: "https://github.com/jailbreakdotparty")!)
                    CreditsRow(name: "SerStars", role: NSLocalizedString("credit_tendies_repo", tableName: "SettingsView", comment: ""), profile: URL(string: "https://github.com/SerStars")!)
                    CreditsRow(name: "Hikariman", role: NSLocalizedString("credit_localization_project", tableName: "SettingsView", comment: ""), profile: URL(string: "https://github.com/ISvetUNot")!)
                } header: {
                    Label(NSLocalizedString("credits", tableName: "SettingsView", comment: ""), systemImage: "person.3.fill")
                }
                Section {
                    Button {
                        show_language_picker = true
                    } label: {
                        HStack {
                            Label(NSLocalizedString("language", tableName: "LanguageView", comment: ""), systemImage: "globe")

                            Spacer()

                            Text(current_language_label)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle(NSLocalizedString("settings", tableName: "SettingsView", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text(NSLocalizedString("done", comment: ""))
                        }
                    }
                }
            }
            .sheet(isPresented: $show_language_picker) {
                LanguageView()
            }
            .alert(NSLocalizedString("are_you_sure", tableName: "SettingsView", comment: ""), isPresented: $show_confirm) {
                Button(NSLocalizedString("cancel", comment: "")) {
                    show_confirm = false
                }
                
                Button(NSLocalizedString("confirm", tableName: "SettingsView", comment: "")) {
                    state.respring()
                }
            } message: {
                Text(NSLocalizedString("confirm_respring", tableName: "SettingsView", comment: ""))
            }
        }
    }

    private var current_language_label: String {
        if language_manager.current == "system" {
            return NSLocalizedString("system_default", tableName: "LanguageView", comment: "")
        }
        return AppLanguage.supported.first { $0.id == language_manager.current }?.nativeName ?? ""
    }
}

struct CreditsRow: View {
    let name: String
    let role: String
    let profile: URL

    private var pfp: URL? {
        URL(string: profile.absoluteString + ".png")
    }

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: pfp) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onTapGesture {
            UIApplication.shared.open(profile)
        }
    }
}
