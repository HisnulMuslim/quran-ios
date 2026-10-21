//
//  AudioBannerViewUI.swift
//
//
//  Created by Mohamed Afifi on 2024-09-02.
//

import Localization
import SwiftUI
import UIKit
import UIx

public enum SleepTimerOption: Hashable, Sendable {
    case off
    case minutes(Int)
    case endOfSurah
}

public enum AudioBannerState {
    case playing(paused: Bool, rate: Float, sleepTimerOption: SleepTimerOption, sleepTimeRemaining: TimeInterval?)
    case readyToPlay(reciter: String)
    case downloading(progress: Double)
}

public struct AudioBannerActions {
    let play: () -> Void
    let pause: () -> Void
    let resume: () -> Void
    let stop: () -> Void
    let backward: () -> Void
    let forward: () -> Void
    let cancelDownloading: AsyncAction
    let reciters: () -> Void
    let more: () -> Void
    let setPlaybackRate: (Float) -> Void
    let setSleepTimer: (SleepTimerOption) -> Void

    public init(
        play: @escaping () -> Void,
        pause: @escaping () -> Void,
        resume: @escaping () -> Void,
        stop: @escaping () -> Void,
        backward: @escaping () -> Void,
        forward: @escaping () -> Void,
        cancelDownloading: @escaping AsyncAction,
        reciters: @escaping () -> Void,
        more: @escaping () -> Void,
        setPlaybackRate: @escaping (Float) -> Void,
        setSleepTimer: @escaping (SleepTimerOption) -> Void
    ) {
        self.play = play
        self.pause = pause
        self.resume = resume
        self.stop = stop
        self.backward = backward
        self.forward = forward
        self.cancelDownloading = cancelDownloading
        self.reciters = reciters
        self.more = more
        self.setPlaybackRate = setPlaybackRate
        self.setSleepTimer = setSleepTimer
    }
}

public struct AudioBannerViewUI: View {
    private let state: AudioBannerState
    private let actions: AudioBannerActions
    public init(state: AudioBannerState, actions: AudioBannerActions) {
        self.state = state
        self.actions = actions
    }

    public var body: some View {
        ZStack {
            switch state {
            case .playing(let paused, let rate, let sleepTimerOption, let sleepTimeRemaining):
                AudioPlaying(
                    paused: paused,
                    currentRate: rate,
                    sleepTimerOption: sleepTimerOption,
                    sleepTimeRemaining: sleepTimeRemaining,
                    actions: actions
                )
            case .readyToPlay(let reciter):
                ReadyToPlay(reciter: reciter, actions: actions)
            case .downloading(let progress):
                Downloading(progress: progress, actions: actions)
            }
        }
        .font(.title2)
        .background(
            BannerBackground(color: .clear)
                .shadow(color: .label.opacity(0.33), radius: 2)
        )
    }
}

private let speedValues: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5]

private let speedFormatter: NumberFormatter = {
    let nf = NumberFormatter()
    nf.locale = Locale.current.fixedLocaleNumbers()
    nf.minimumFractionDigits = 0
    nf.maximumFractionDigits = 2
    return nf
}()

private func formattedSpeed(_ rate: Float) -> String {
    // TODO: Localize this
    return speedFormatter.format(rate) + "×"
}

private func formatTimeRemaining(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

private struct AudioPlaying: View {
    let paused: Bool
    let currentRate: Float
    let sleepTimerOption: SleepTimerOption
    let sleepTimeRemaining: TimeInterval?
    let actions: AudioBannerActions

    private func setPlaybackRateWithoutAnimation(_ rate: Float) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            UIView.performWithoutAnimation {
                actions.setPlaybackRate(rate)
            }
        }
    }

    private func setSleepTimerWithoutAnimation(_ option: SleepTimerOption) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            UIView.performWithoutAnimation {
                actions.setSleepTimer(option)
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: actions.stop) {
                NoorSystemImage.stop.image
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }

            Menu {
                ForEach(speedValues, id: \.self) { value in
                    Button(formattedSpeed(value)) { setPlaybackRateWithoutAnimation(value) }
                }
            } label: {
                Text(formattedSpeed(currentRate))
                    .font(.footnote)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .fixedSize()
            .transaction { transaction in
                transaction.animation = nil
            }

            // Sleep Timer Menu
            Menu {
                Button(l("audio.sleep_timer.off")) { setSleepTimerWithoutAnimation(.off) }
                Button(lFormat("audio.sleep_timer.minutes", 5)) { setSleepTimerWithoutAnimation(.minutes(5)) }
                Button(lFormat("audio.sleep_timer.minutes", 10)) { setSleepTimerWithoutAnimation(.minutes(10)) }
                Button(lFormat("audio.sleep_timer.minutes", 15)) { setSleepTimerWithoutAnimation(.minutes(15)) }
                Button(lFormat("audio.sleep_timer.minutes", 30)) { setSleepTimerWithoutAnimation(.minutes(30)) }
                Button(lFormat("audio.sleep_timer.minutes", 45)) { setSleepTimerWithoutAnimation(.minutes(45)) }
                Button(lFormat("audio.sleep_timer.minutes", 60)) { setSleepTimerWithoutAnimation(.minutes(60)) }
                Button(l("audio.sleep_timer.end_of_surah")) { setSleepTimerWithoutAnimation(.endOfSurah) }
            } label: {
                ZStack {
                    // Stable footprint: retains maximum width from the start so the Menu
                    // container never has to expand from narrow to wide on the first selection.
                    HStack(spacing: 2) {
                        NoorSystemImage.sleepActive.image
                        ZStack {
                            Text(formatTimeRemaining(3600))
                                .font(.caption2.monospacedDigit())
                            Text(l("surah"))
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .hidden()

                    if let remaining = sleepTimeRemaining {
                        HStack(spacing: 2) {
                            NoorSystemImage.sleepActive.image
                            Text(formatTimeRemaining(remaining))
                                .font(.caption2.monospacedDigit())
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundColor(.accentColor)
                    } else if case .endOfSurah = sleepTimerOption {
                        HStack(spacing: 2) {
                            NoorSystemImage.sleepActive.image
                            Text(l("surah"))
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundColor(.accentColor)
                    } else {
                        NoorSystemImage.sleep.image
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .fixedSize()
            .transaction { transaction in
                transaction.animation = nil
            }

            Spacer(minLength: 4)

            Button(action: actions.backward) {
                NoorSystemImage.backward.image
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
            Group {
                if paused {
                    Button(action: actions.resume) {
                        NoorSystemImage.play.image
                    }
                } else {
                    Button(action: actions.pause) {
                        NoorSystemImage.pause.image
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            Button(action: actions.forward) {
                NoorSystemImage.forward.image
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }

            Spacer(minLength: 4)

            Button(action: actions.more) {
                NoorSystemImage.more.image
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
        }
        .animation(nil, value: sleepTimerOption)
        .animation(nil, value: sleepTimeRemaining)
        .animation(nil, value: currentRate)
    }
}

private struct ReadyToPlay: View {
    let reciter: String
    let actions: AudioBannerActions
    var body: some View {
        ZStack {
            HStack {
                Button(action: actions.play) {
                    NoorSystemImage.play.image
                        .padding()
                }
                Spacer()
                Text(reciter)
                    .font(.body)
                    .lineLimit(1)
                Spacer()
                Button(action: actions.more) {
                    NoorSystemImage.more.image
                        .padding()
                }
            }
            .background {
                Button(action: actions.reciters) {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(CustomButtonStyle { config in
                    config.label
                        .background(
                            BannerBackground(color: config.isPressed ? .systemFill : Color.clear)
                        )
                })
            }
        }
    }
}

private struct Downloading: View {
    let progress: Double
    let actions: AudioBannerActions
    var body: some View {
        HStack {
            AsyncButton(action: actions.cancelDownloading) {
                ZStack {
                    // workaround to have uniform height.
                    NoorSystemImage.more.image
                        .padding()
                        .hidden()
                    NoorSystemImage.cancel.image
                        .padding()
                }
                .overlay(Divider(), alignment: .trailing)
            }

            Spacer()
            VStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())

                Text(l("downloading_title"))
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing)
        }
    }
}

private struct BannerBackground: View {
    let color: Color
    @ScaledMetric private var cornerRadius = Dimensions.cornerRadius

    var body: some View {
        color
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
    }
}

#Preview {
    struct PreviewView: View {
        let actions = AudioBannerActions(
            play: {},
            pause: {},
            resume: {},
            stop: {},
            backward: {},
            forward: {},
            cancelDownloading: {},
            reciters: {},
            more: {},
            setPlaybackRate: { _ in },
            setSleepTimer: { _ in }
        )

        let readyToPlay = AudioBannerState.readyToPlay(reciter: "Mishary Al-afasy")
        let playing = AudioBannerState.playing(paused: false, rate: 1.0, sleepTimerOption: .off, sleepTimeRemaining: nil)
        let downloading = AudioBannerState.downloading(progress: 0.7)
        var state: AudioBannerState {
            switch counter % 3 {
            case 0: readyToPlay
            case 1: playing
            default: downloading
            }
        }

        @State var counter: Int = 0

        var body: some View {
            VStack {
                Spacer()
                Button {
                    counter += 1
                } label: {
                    Text("Rotate")
                }
                Spacer()
                Group {
                    AudioBannerViewUI(state: state, actions: actions)
                }
            }
        }
    }

    return PreviewView()
}
