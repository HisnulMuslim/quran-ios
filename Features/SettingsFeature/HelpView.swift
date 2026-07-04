import Localization
import NoorUI
import SwiftUI
import UIx

struct HelpView: View {
    private struct FAQ: Identifiable {
        let id: Int
        let question: String
        let answer: String
    }

    private var faqs: [FAQ] {
        [
            FAQ(id: 1, question: lAndroid("help_q1_question"), answer: lAndroid("help_q1_answer")),
            FAQ(id: 2, question: lAndroid("help_q2_question"), answer: lAndroid("help_q2_answer")),
            FAQ(id: 3, question: lAndroid("help_q3_question"), answer: lAndroid("help_q3_answer")),
            FAQ(id: 4, question: lAndroid("help_q4_question"), answer: lAndroid("help_q4_answer")),
            FAQ(id: 5, question: lAndroid("help_q5_question"), answer: lAndroid("help_q5_answer")),
        ]
    }

    var body: some View {
        NoorList {
            NoorSection(title: lAndroid("help_page_title"), faqs) { faq in
                NoorListItem(
                    title: .text(faq.question),
                    subtitle: .init(text: faq.answer, location: .bottom)
                )
            }

            NoorBasicSection(footer: lAndroid("help_footer_contact_text")) {
                NoorListItem(
                    title: .text("hmkannada@gmail.com"),
                    accessory: .disclosureIndicator
                ) {
                    openSupportEmail()
                }
            }
        }
    }
}
