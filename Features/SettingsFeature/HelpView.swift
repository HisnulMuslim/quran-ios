import SwiftUI
import Localization
import UIx
import NoorUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(AppLanguage == .kannada ? "ಪದೇ ಪದೇ ಕೇಳಲಾಗುವ ಪ್ರಶ್ನೆಗಳು" : "Frequently Asked Questions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                FAQItem(
                    question: AppLanguage == .kannada ? "ನಾನು ಪಠ್ಯವನ್ನು ಹೇಗೆ ದೊಡ್ಡದಾಗಿ ಮಾಡಬಹುದು?" : "How do I make the text larger?",
                    answer: AppLanguage == .kannada ? "ಅರೇಬಿಕ್ ಪುಟಗಳಿಗಾಗಿ, ನಿಮ್ಮ ಫೋನ್ ಅನ್ನು ಲ್ಯಾಂಡ್‌ಸ್ಕೇಪ್‌ನಲ್ಲಿ ಹಿಡಿದುಕೊಳ್ಳಿ. ಇದು ಪಠ್ಯವನ್ನು ದೊಡ್ಡದಾಗಿ ಮಾಡುತ್ತದೆ. ಅನುವಾದಗಳಿಗಾಗಿ, ಸೆಟ್ಟಿಂಗ್‌ಗಳಿಗೆ ಹೋಗಿ ಮತ್ತು ಅನುವಾದ ಪಠ್ಯದ ಗಾತ್ರವನ್ನು ಹೊಂದಿಸಿ." : "For the Arabic pages, hold your phone in landscape. This makes the text larger. For translations, go to settings and set translation text size."
                )
                
                FAQItem(
                    question: AppLanguage == .kannada ? "ನಾನು ಆಡಿಯೊವನ್ನು ಹೇಗೆ ಪ್ಲೇ ಮಾಡಬಹುದು?" : "How do I play audio?",
                    answer: AppLanguage == .kannada ? "ಯಾವುದೇ ಕುರಾನ್ ಪುಟವನ್ನು ತೆರೆಯಿರಿ. ಪರದೆಯ ಮೇಲೆ ಒಮ್ಮೆ ಟ್ಯಾಪ್ ಮಾಡಿ. ಕೆಳಭಾಗದಲ್ಲಿ, ನೀವು ಪ್ಲೇ ಬಟನ್ ಮತ್ತು ಖಾರಿಯ ಹೆಸರಿನ ಕೆಲವು ಪಠ್ಯವನ್ನು ಗಮನಿಸಬಹುದು. ಬೇರೆ ಖಾರಿಯನ್ನು ಆಯ್ಕೆ ಮಾಡಲು ಖಾರಿಯ ಹೆಸರನ್ನು ಕ್ಲಿಕ್ ಮಾಡಿ. ಪ್ರಸ್ತುತ ಪುಟ ಅಥವಾ ಸೂರಾವನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಮತ್ತು ಪ್ಲೇ ಮಾಡಲು ಪ್ಲೇ ಕ್ಲಿಕ್ ಮಾಡಿ." : "Open any Quran page. Tap on the screen once. At the bottom, you will notice a play button and some text with the name of a qari. Click the name of the qari to choose a different qari. Click play to download and play the current page or sura."
                )
                
                FAQItem(
                    question: AppLanguage == .kannada ? "ನಾನು ಅನುವಾದವನ್ನು ಹೇಗೆ ವೀಕ್ಷಿಸಬಲ್ಲೆ?" : "How do I view translation?",
                    answer: AppLanguage == .kannada ? "ಯಾವುದೇ ಕುರಾನ್ ಪುಟವನ್ನು ತೆರೆಯಿರಿ. ಪರದೆಯ ಮೇಲೆ ಒಮ್ಮೆ ಟ್ಯಾಪ್ ಮಾಡಿ. ಮೇಲ್ಭಾಗದಲ್ಲಿ, ನೀವು ಗ್ಲೋಬ್ ಐಕಾನ್ ಅನ್ನು ಗಮನಿಸಬಹುದು (ಅಥವಾ, ನೀವು ಅದನ್ನು ನೋಡದಿದ್ದರೆ, ಮೂರು ಚೌಕ ಚುಕ್ಕೆಗಳನ್ನು ಹೊಂದಿರುವ ಐಕಾನ್ ಅನ್ನು ಕ್ಲಿಕ್ ಮಾಡಿ) - ಅನುವಾದವನ್ನು ವೀಕ್ಷಿಸಲು ಇದನ್ನು ಕ್ಲಿಕ್ ಮಾಡಿ ಮತ್ತು ಅನುವಾದವನ್ನು ಆಯ್ಕೆಮಾಡಿ.\nನೀವು ಯಾವುದೇ ಅನುವಾದಗಳನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡದಿದ್ದರೆ, ನೀವು ಅನುವಾದಗಳನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಬಹುದಾದ ಪರದೆಯತ್ತ ಇದು ನಿಮ್ಮನ್ನು ಕರೆದೊಯ್ಯುತ್ತದೆ. ಅನುವಾದವನ್ನು ಆರಿಸಿ ಮತ್ತು ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ, ನಂತರ ಹಿಂತಿರುಗಿ ಮತ್ತು ಅನುವಾದವನ್ನು ವೀಕ್ಷಿಸಲು ಗ್ಲೋಬ್ ಐಕಾನ್ ಅನ್ನು ಮತ್ತೊಮ್ಮೆ ಟ್ಯಾಪ್ ಮಾಡಿ." : "Open any Quran page. Tap on the screen once. In the top, you will notice a globe icon (or, if you don't see it, click an icon with three square dots) - click this and choose translation to view the translation.\nIf you do not have any translations downloaded, it will take you to a screen where you can download translations. Choose and download a translation, then return back and tap the globe icon again to view the translation."
                )
                
                FAQItem(
                    question: AppLanguage == .kannada ? "ನಾನು ಪುಟವನ್ನು ಹೇಗೆ ಬುಕ್‌ಮಾರ್ಕ್ ಮಾಡುವುದು?" : "How do I bookmark a page?",
                    answer: AppLanguage == .kannada ? "ಯಾವುದೇ ಕುರಾನ್ ಪುಟವನ್ನು ತೆರೆಯಿರಿ. ಪರದೆಯ ಮೇಲೆ ಒಮ್ಮೆ ಟ್ಯಾಪ್ ಮಾಡಿ. ಮೇಲಿನ ಬಲಭಾಗದಲ್ಲಿ, ನೀವು ಬುಕ್‌ಮಾರ್ಕ್ ಐಕಾನ್ ಅನ್ನು ನೋಡುತ್ತೀರಿ. ಪುಟವನ್ನು ಬುಕ್‌ಮಾರ್ಕ್ ಮಾಡಲು ಐಕಾನ್ ಅನ್ನು ಟ್ಯಾಪ್ ಮಾಡಿ (ಬಣ್ಣವು ಘನ ಬಿಳಿ ಬಣ್ಣಕ್ಕೆ ತಿರುಗುತ್ತದೆ). ಬುಕ್‌ಮಾರ್ಕ್ ತೆಗೆದುಹಾಕಲು ಬುಕ್‌ಮಾರ್ಕ್ ಐಕಾನ್ ಅನ್ನು ಮತ್ತೊಮ್ಮೆ ಟ್ಯಾಪ್ ಮಾಡಿ." : "Open any Quran page. Tap on the screen once. In the top right, you will see a bookmark icon. Tap the bookmark icon to bookmark the page (the color will turn solid white). Tap the bookmark icon again to remove the bookmark."
                )
                
                FAQItem(
                    question: AppLanguage == .kannada ? "ನಾನು ಆಯತ್ ಅನ್ನು ಹೇಗೆ ಹಂಚಿಕೊಳ್ಳಬಹುದು?" : "How do I share an ayah?",
                    answer: AppLanguage == .kannada ? "ಯಾವುದೇ ಅರೇಬಿಕ್ ಪುಟದಲ್ಲಿರುವಾಗ, ಆಯತ್ ಅನ್ನು ಬುಕ್‌ಮಾರ್ಕ್ ಮಾಡಲು, ಟ್ಯಾಗ್ ಮಾಡಲು, ಹಂಚಿಕೊಳ್ಳಲು ಅಥವಾ ಕ್ಲಿಪ್‌ಬೋರ್ಡ್‌ಗೆ ನಕಲಿಸಲು, ಅನುವಾದವನ್ನು ನೋಡಲು ಅಥವಾ ಅದರ ಪಠಣವನ್ನು ಕೇಳಲು ನೀವು ಆಯ್ಕೆಮಾಡಬಲ್ಲ ಮೆನುವನ್ನು ಪಡೆಯಲು ಯಾವುದೇ ಆಯತ್ ಅನ್ನು ಒತ್ತಿ ಹಿಡಿದುಕೊಳ್ಳಿ." : "While on any Arabic page, press and hold on any ayah to get a menu where you can choose to bookmark, tag, share or copy that ayah to the clipboard, see the translation, or listen to its recitation."
                )
                
                Text(AppLanguage == .kannada ? "ನಿಮ್ಮ ಪ್ರಶ್ನೆಗೆ ಮೇಲೆ ಉತ್ತರಿಸದಿದ್ದರೆ, ಬೆಂಬಲಕ್ಕಾಗಿ ನೀವು hmkannada@gmail.com ಗೆ ಇಮೇಲ್ ಮಾಡಬಹುದು. ದಯವಿಟ್ಟು ಗಮನಿಸಿ, ನಾವು ಸಾಕಷ್ಟು ಇಮೇಲ್‌ಗಳನ್ನು ಸ್ವೀಕರಿಸುತ್ತೇವೆ, ಆದ್ದರಿಂದ ನಾವು ಎಲ್ಲದಕ್ಕೂ ಪ್ರತ್ಯುತ್ತರಿಸಲು ಸಾಧ್ಯವಾಗದಿರಬಹುದು." : "If your question is not answered above, you can email hmkannada@gmail.com for support. Please note that we receive lots of emails, so we may not be able to reply to all of them.")
                    .font(.body)
                    .padding(.top, 20)
            }
            .padding()
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.headline)
            Text(answer)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
