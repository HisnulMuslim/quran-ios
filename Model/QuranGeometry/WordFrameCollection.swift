//
//  WordFrameCollection.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import CoreGraphics
import QuranKit

public struct WordFrameCollection: Equatable {
    public var lines: [WordFrameLine]

    public init(lines: [WordFrameLine]) {
        self.lines = lines
    }

    public func wordFramesForVerse(_ verse: AyahNumber) -> [WordFrame] {
        lines
            .flatMap(\.frames)
            .filter { $0.word.verse == verse }
    }

    public func lineFramesVerVerse(_ verse: AyahNumber) -> [WordFrameLine] {
        lines.filter { line in
            line.frames.contains { $0.word.verse == verse }
        }
    }

    public func wordFrameForWord(_ word: Word) -> WordFrame? {
        let frames = wordFramesForVerse(word.verse)
        return frames.first(where: { $0.word == word })
    }

    public func wordAtLocation(_ location: CGPoint, imageScale: WordFrameScale) -> Word? {
        let flattenFrames = lines.flatMap(\.frames)
        guard !flattenFrames.isEmpty else {
            return nil
        }
        for frame in flattenFrames {
            let rectangle = frame.rect.scaled(by: imageScale)
            if rectangle.contains(location) {
                return frame.word
            }
        }
        // Fallback to closest word frame for margins, line gaps, and decorative headers
        var closestWord: Word?
        var minDistance: CGFloat = .greatestFiniteMagnitude
        for frame in flattenFrames {
            let rectangle = frame.rect.scaled(by: imageScale)
            let dx = max(0, max(rectangle.minX - location.x, location.x - rectangle.maxX))
            let dy = max(0, max(rectangle.minY - location.y, location.y - rectangle.maxY))
            let distance = dy * 2.0 + dx
            if distance < minDistance {
                minDistance = distance
                closestWord = frame.word
            }
        }
        return closestWord
    }

    public func topPadding(atLineIndex lineIndex: Int, scale: WordFrameScale) -> CGFloat {
        let topLine = lineIndex == 0 ? 0 : lines[lineIndex - 1].frames[0].maxY
        let padding = CGFloat(lines[lineIndex].frames[0].minY - topLine)
        return padding * scale.scale
    }
}
