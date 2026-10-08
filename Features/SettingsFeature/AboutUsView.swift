import Localization
import NoorUI
import SettingsService
import SwiftUI
import UIx

struct AboutUsView: View {
    private struct DataSourceItem: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let url: String
    }

    // MARK: Internal

    var body: some View {
        NoorList {
            NoorBasicSection {
                VStack(alignment: .center, spacing: 20) {
                    Text(lAndroid("about_us_title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    Text(lAndroid("about_us_description"))
                        .font(.body)
                        .multilineTextAlignment(.center)

                    Text(lAndroid("about_us_open_source_description"))
                        .font(.body)
                        .multilineTextAlignment(.center)

                    Text(lAndroid("about_us_translation_credits"))
                        .font(.body)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 8) {
                        Text(lAndroid("about_us_translation_title"))
                        Text(lAndroid("about_us_publisher"))
                    }
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                }
            }

            NoorSection(title: lAndroid("about_data_sources"), sources) { source in
                NoorListItem(
                    title: .text(source.title),
                    subtitle: .init(text: source.subtitle, location: .bottom),
                    accessory: .disclosureIndicator
                ) {
                    if let url = URL(string: source.url) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.otherApps),
                    title: .text(lAndroid("menu_other_apps")),
                    accessory: .disclosureIndicator
                ) {
                    ReviewService.openDeveloperApps()
                }
            }

            NoorBasicSection(title: lAndroid("about_us_contact_us"), footer: lAndroid("about_us_copyright")) {
                NoorListItem(
                    title: .text("hmkannada@gmail.com"),
                    accessory: .disclosureIndicator
                ) {
                    openSupportEmail()
                }
            }

            NoorBasicSection {
                VStack(spacing: 8) {
                    Text(lAndroid("about_us_sponsored_by"))
                        .font(.footnote)

                    HStack(spacing: 24) {
                        Image("ksa-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)

                        Image("wisdom-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 32)
                    }
                    .padding(.vertical, 4)

                    Text(lAndroid("about_us_sponsor_name"))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: Private

    private var sources: [DataSourceItem] {
        [
            DataSourceItem(id: 1, title: lAndroid("about_images"), subtitle: lAndroid("about_madani_images"), url: "https://github.com/quran/quran.com-images"),
            DataSourceItem(id: 2, title: "QuranicAudio", subtitle: lAndroid("about_quranicaudio_summary"), url: "https://quranicaudio.com/"),
        ]
    }
}
