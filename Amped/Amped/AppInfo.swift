//
//  AppInfo.swift
//  Amped
//
//  Created by Kevin Choo on 8/15/23.
//

import Foundation
import SwiftUI

struct AppInfo: View {
    var body: some View {
        VStack {
            Text("""
Ebikes are typically 17 cents/min. Non-ebikes are free for members, up to 45 mins. After that, the pricing is 17 cents/min for all bikes. However, if there are only ebikes at a station, they are free for members (like a non-ebike would be). Furthermore, if you park the bike within the 45 mins at an empty station and rescan it, you can get another free 45mins.\n\nWe built this app to help you find empty stations and ones with only ebikes. If you're trying to get an ebike, our suggestion is to wait on the app for a couple minutes until a blue pin pops up next you to you and go there quickly. Stations with only ebikes tend to popup quickly and only last a couple minutes (until someone parks a traditional bike or all the ebikes are taken). If you have any suggestions, feel free to reach out to us.\n
""")
            
            .font(.body)
            .fontWeight(.regular)
            HStack {
                Text("- ")
                Link("Vlad", destination: URL(string: "https://twitter.com/0x07b5")!)
                Text("&")
                Link("Kevin", destination: URL(string: "https://www.linkedin.com/in/kevin-choo-989135147/")!)
            }
        }
        .padding()
    }
}
