import SwiftUI
import Localization
import UIx

struct AboutUsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                Text(AppLanguage == .kannada ? "ಪವಿತ್ರ ಕುರ್ ಆನ್" : "The Holy Qur'an")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                Text(AppLanguage == .kannada ? "ಪವಿತ್ರ ಕುರ್ ಆನ್ — ಆಂಡ್ರಾಯ್ಡ್‌ ಸ್ಮಾರ್ಟ್‌ಫೋನ್‌ಗಳಿಗಾಗಿ ವಿನ್ಯಾಸಗೊಳಿಸಲಾದ ಉಚಿತ ಕನ್ನಡ ಕುರಾನ್ ಅಪ್ಲಿಕೇಶನ್." : "The Holy Qur’an — a free Kannada Qur’an application designed for Android smartphones.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text(AppLanguage == .kannada ? "ಈ ಅಪ್ಲಿಕೇಶನ್ ಅನ್ನು ಓಪನ್ ಸೋರ್ಸ್ ಆಂಡ್ರಾಯ್ಡ್‌ ಪ್ರಾಜೆಕ್ಟ್ QURAN.COM ಬಳಸಿ ಅಭಿವೃದ್ಧಿಪಡಿಸಲಾಗಿದೆ. ಅಲ್ಲಾಹ್ ಅವರಿಗೆ ಉತ್ತಮ ಪ್ರತಿಫಲವನ್ನು ನೀಡಲಿ." : "This application has been developed using the open-source Android project QURAN.COM .May Allah reward them with the best of rewards.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text(AppLanguage == .kannada ? "ಕನ್ನಡ ಅನುವಾದವನ್ನು ಮುಹಮ್ಮದ್ ಹಮ್ಜಾ ಪುತ್ತೂರು ಅವರು ಅನುವಾದಿಸಿದ್ದಾರೆ ಮತ್ತು ಉಮರ್ ಇಬ್ನ್ ಅಹ್ಮದ್ ಮದನಿ, ಅಹ್ಮದ್ ಎಸ್. ಎಮ್., ಮತ್ತು ಅಬೂಬಕರ್ ನಝೀರ್ ಸಲಾಫಿ ಪರಿಶೀಲಿಸಿದ್ದಾರೆ." : "The Kannada translation was translated by Muhammad Hamza Puttur and reviewed by Umar ibn Ahmad Madani, Ahmad S. M., and Abu Bakr Nazeer Salafi.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Text(AppLanguage == .kannada ? "ಪವಿತ್ರ ಕುರಾನ್ ಮತ್ತು ಅದರ ಕನ್ನಡ ಅನುವಾದ" : "The Noble Qur’an along with its Kannada translation")
                    Text(AppLanguage == .kannada ? "ಪ್ರಕಾಶಕರು: ಕಿಂಗ್ ಫಹದ್ ಪವಿತ್ರ ಕುರಾನ್ ಮುದ್ರಣ ಸಂಕೀರ್ಣ, ಮದೀನಾ, ಸೌದಿ ಅರೇಬಿಯಾ" : "Publisher: King Fahd Holy Quran Printing Complex, Madinah, Saudi Arabia")
                }
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.vertical)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLanguage == .kannada ? "ಡೇಟಾ ಮೂಲಗಳು" : "Data Sources")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Link(AppLanguage == .kannada ? "ಚಿತ್ರಗಳು" : "Images", destination: URL(string: "https://github.com/quran/quran.com-images")!)
                            .foregroundColor(.blue)
                        Text(AppLanguage == .kannada ? "ಕುರಾನ್ ಚಿತ್ರಗಳು ಕಿಂಗ್ ಫಹದ್ ಕುರಾನ್ ಮುದ್ರಣ ಸಂಕೀರ್ಣದ ಫಾಂಟ್‌ಗಳನ್ನು ಆಧರಿಸಿವೆ" : "The Quran images are based on the fonts from the King Fahd Quran Printing Complex")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Link("QuranicAudio", destination: URL(string: "https://quranicaudio.com/")!)
                            .foregroundColor(.blue)
                        Text(AppLanguage == .kannada ? "ಗ್ಯಾಪ್‌ಲೆಸ್ mp3 ಕುರಾನ್ ಪಠಣಗಳು" : "Gapless mp3 Quran recitations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                
                VStack(spacing: 10) {
                    Text(AppLanguage == .kannada ? "ನಮ್ಮನ್ನು ಸಂಪರ್ಕಿಸಿ" : "Contact us")
                        .font(.headline)
                    
                    Text(AppLanguage == .kannada ? "©ಕನ್ನಡ ಕುರಾನ್ ಅಪ್ಲಿಕೇಶನ್" : "©Kannada Quran Application")
                    
                    Link("hmkannada@gmail.com", destination: URL(string: "mailto:hmkannada@gmail.com?subject=Kannada%20Quran%20App%20Support")!)
                        .foregroundColor(.blue)
                }
                .padding(.vertical)
                
               Divider()
                
                VStack(spacing: 5) {
                    Text(AppLanguage == .kannada ? "ಪ್ರಾಯೋಜಕರು" : "Sponsored by")
                        .font(.footnote)
                    
                    Image("ksa-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        
                    Text(AppLanguage == .kannada ? "ಕರ್ನಾಟಕ ಸಲಾಫಿ ಅಸೋಸಿಯೇಷನ್" : "Karnataka Salafi Association")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
    }
}
