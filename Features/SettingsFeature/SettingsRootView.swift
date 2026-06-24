//
//  SettingsRootView.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//
//

import Localization
import NoorUI
import SwiftUI
import UIx

struct SettingsRootView: View {
    @StateObject var viewModel: SettingsRootViewModel

    var body: some View {
        SettingsRootViewUI(
            appearanceMode: $viewModel.appearanceMode,
            audioEnd: viewModel.audioEnd.name,
            navigateToLanguageSelector: { viewModel.navigateToLanguageSelector() },
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToShareSettings: { viewModel.navigateToShareSettings() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            navigateToHelp: { viewModel.navigateToHelp() },
            navigateToAboutUs: { viewModel.navigateToAboutUs() },
            loginAction: { await viewModel.loginToQuranCom() }
        )
    }
}

private struct SettingsRootViewUI: View {
    @Binding var appearanceMode: AppearanceMode

    let audioEnd: String
    let navigateToLanguageSelector: AsyncAction
    let navigateToAudioEndSelector: AsyncAction
    let navigateToAudioManager: AsyncAction
    let navigateToTranslationsList: AsyncAction
    let navigateToShareSettings: AsyncAction
    let navigateToReadingSelector: AsyncAction
    let navigateToHelp: AsyncAction
    let navigateToAboutUs: AsyncAction
    let loginAction: AsyncAction

    var body: some View {
        NoorList {
            NoorBasicSection {
                VStack {
                    AppearanceModeSelector(appearanceMode: $appearanceMode)
                }
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.translation),
                    title: .text(AppLanguage == .kannada ? "ಆ್ಯಪ್ ಭಾಷೆ" : "App Language"),
                    subtitle: .init(text: AppLanguage == .kannada ? "ಕನ್ನಡ" : "English", location: .trailing),
                    accessory: .disclosureIndicator,
                    action: navigateToLanguageSelector
                )

                NoorListItem(
                    image: .init(.mushafs),
                    title: .text(l("reading.selector.title")),
                    accessory: .disclosureIndicator,
                    action: navigateToReadingSelector
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.audio),
                    title: .text(l("audio.download-play-amount")),
                    subtitle: .init(text: audioEnd, location: .trailing),
                    accessory: .disclosureIndicator,
                    action: navigateToAudioEndSelector
                )

                NoorListItem(
                    image: .init(.downloads),
                    title: .text(lAndroid("audio_manager")),
                    accessory: .disclosureIndicator,
                    action: navigateToAudioManager
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.translation),
                    title: .text(lAndroid("prefs_translations")),
                    accessory: .disclosureIndicator,
                    action: navigateToTranslationsList
                )

                NoorListItem(
                    image: .init(.share),
                    title: .text(lAndroid("prefs_category_sharing")),
                    accessory: .disclosureIndicator,
                    action: navigateToShareSettings
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.help), // Need an appropriate icon, like .questionmark or similar, let's use a standard SF Symbol if needed, but since it's NoorListItem, maybe .help or similar exists. Wait, I will use a generic SF Symbol image if needed.
                    title: .text(AppLanguage == .kannada ? "ಸಹಾಯ" : "Help"),
                    accessory: .disclosureIndicator,
                    action: navigateToHelp
                )

                NoorListItem(
                    image: .init(.info), // Assuming .info exists, else we can change it later.
                    title: .text(AppLanguage == .kannada ? "ನಮ್ಮ ಬಗ್ಗೆ" : "About Us"),
                    accessory: .disclosureIndicator,
                    action: navigateToAboutUs
                )
            }

            #if QURAN_SYNC
                // TODO: Pending translations, and hiding if OAuth is not configured.
                NoorBasicSection {
                    NoorListItem(
                        title: .text(l("Login with Quran.com")),
                        action: loginAction
                    )
                }
            #endif


        }
    }
}

struct SettingsRootView_Previews: PreviewProvider {
    struct Container: View {
        @State var appearanceMode: AppearanceMode

        var body: some View {
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                audioEnd: "Surah",
                navigateToLanguageSelector: {},
                navigateToAudioEndSelector: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToShareSettings: {},
                navigateToReadingSelector: {},
                navigateToHelp: {},
                navigateToAboutUs: {},
                loginAction: {}
            )
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container(appearanceMode: .auto)
        }
    }
}