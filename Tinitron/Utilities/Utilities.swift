//
//  Utilities.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/11/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Foundation

func saveImage(imageName: String, image: UIImage) {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

    let fileName = imageName
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    guard let data = image.jpegData(compressionQuality: 1) else { return }

    //Checks if file exists, removes it if so.
    if FileManager.default.fileExists(atPath: fileURL.path) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
            print("Removed old image")
        } catch let removeError {
            print("couldn't remove file at path", removeError)
        }
    }

    do {
        try data.write(to: fileURL)
    } catch let error {
        print("error saving file with error", error)
    }
}

func loadImageFromDiskWith(fileName: String) -> UIImage? {
    let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

    let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
    let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)

    if let dirPath = paths.first {
        let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
        let image = UIImage(contentsOfFile: imageUrl.path)
        return image
    }
    return nil
}

func verifyUrl (urlString: String?) -> Bool {
    if let urlString = urlString {
        if let url = NSURL(string: urlString) {
            return UIApplication.shared.canOpenURL(url as URL)
        }
    }
    return false
}

func generateRandomLinks(count: Int) -> [Link] {
    var links = [Link]()

    for _ in 0..<count {
        let originalURL = "https://www.\(randomWord()).com"
        let title = Bool.random() ? originalURL : randomWord() + " " + randomWord()
        let creationDate = Date.randomWithinDaysBeforeToday(14)
        let expirationDate = Bool.random() ?Calendar.current.date(byAdding: .day, value: -5, to: Date()) : Calendar.current.date(byAdding: .day, value: 30, to: creationDate)
        links.append(Link(title: title, creationDate: creationDate, originalURL: originalURL, shortURL: "tinytron.ml/\(randomString(length: 7))", expirationDate: expirationDate!, password: nil))
    }

    return links
}

func generateAllAnalytics(for links: [Link]) -> [LinkAnalytics] {
    var analyticsData = [LinkAnalytics]()

    for link in links {
        analyticsData.append(generateRandomLinkAnalytics(id: link.shortURL))
    }
    return analyticsData
}

func generateRandomLinkAnalytics(id: String) -> LinkAnalytics {
    let lastAccessDate = Date.randomWithinDaysBeforeToday(30)
    let dailyAverage = Int.random(in: 0...110)
    let max = Int.random(in: 0...1000)
    let minimum = Int.random(in: 0...100)

    let perMonthClicks: [String: Int] = ["January": Int.random(in: 0...100),
                                         "February": Int.random(in: 0...100),
                                         "March": Int.random(in: 0...100),
                                         "April": Int.random(in: 0...100),
                                         "May": Int.random(in: 0...100),
                                         "June": Int.random(in: 0...100),
                                         "July": Int.random(in: 0...100),
                                         "August": Int.random(in: 0...100),
                                         "September": Int.random(in: 0...100),
                                         "October": Int.random(in: 0...100),
                                         "November": Int.random(in: 0...100),
                                         "December": Int.random(in: 0...100)]
    let totalPerYear = perMonthClicks.compactMap { Int($1) }.reduce(0, +)

    let browserCounts: [String: Int] = ["ie": Int.random(in: 0...100),
                                        "firefox": Int.random(in: 0...100),
                                        "chrome": Int.random(in: 0...100),
                                        "opera": Int.random(in: 0...100),
                                        "safari": Int.random(in: 0...100),
                                        "others": Int.random(in: 0...100)]

    let osCounts: [String: Int] = ["windows": Int.random(in: 0...100),
                                   "macOs": Int.random(in: 0...100),
                                   "linux": Int.random(in: 0...100),
                                   "android": Int.random(in: 0...100),
                                   "ios": Int.random(in: 0...100),
                                   "others": Int.random(in: 0...100)]

    return LinkAnalytics(id: id, lastAccessDate: lastAccessDate, dailyAverage: dailyAverage, max: max, min: minimum, totalPerYear: totalPerYear, perMonthClicks: perMonthClicks, browserCounts: browserCounts, osCounts: osCounts)
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
}

func randomWord(wordLength: Int = 6) -> String {
    let kCons = 1
    let kVows = 2

    var cons: [String] = [
        // single consonants. Beware of Q, it"s often awkward in words
        "b", "c", "d", "f", "g", "h", "j", "k", "l", "m",
        "n", "p", "r", "s", "t", "v", "w", "x", "z",
        // possible combinations excluding those which cannot start a word
        "pt", "gl", "gr", "ch", "ph", "ps", "sh", "st", "th", "wh"
    ]

    // consonant combinations that cannot start a word
    let consCantStart: [String] = [
        "ck", "cm",
        "dr", "ds",
        "ft",
        "gh", "gn",
        "kr", "ks",
        "ls", "lt", "lr",
        "mp", "mt", "ms",
        "ng", "ns",
        "rd", "rg", "rs", "rt",
        "ss",
        "ts", "tch"
    ]

    let vows: [String] = [
        // single vowels
        "a", "e", "i", "o", "u", "y",
        // vowel combinations your language allows
        "ee", "oa", "oo"
    ]

    // start by vowel or consonant ?
    var current = (Int(arc4random_uniform(2)) == 1 ? kCons : kVows )

    var word: String = ""
    while word.count < wordLength {
        // After first letter, use all consonant combos
        if word.count == 2 {
            cons += consCantStart
        }

        // random sign from either $cons or $vows
        var rnd: String = ""
        var index: Int
        if current == kCons {
            index = Int(arc4random_uniform(UInt32(cons.count)))
            rnd = cons[index]
        } else if current == kVows {
            index = Int(arc4random_uniform(UInt32(vows.count)))
            rnd = vows[index]
        }

        // check if random sign fits in word length
        let tempWord = "\(word)\(rnd)"
        if tempWord.count <= wordLength {
            word = "\(word)\(rnd)"
            // alternate sounds
            current = ( current == kCons ) ? kVows : kCons
        }
    }
    return word
}
