//
//  Settings.swift
//  Amped
//
//  Created by Kevin Choo & Vlad Munteanu on 8/15/23.
//

import Foundation
import SwiftUI

struct Settings: View {
    
    @Binding  var showEmptyStations: Bool
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.headline)
                .padding(.top)
            
            Toggle("Show Empty Stations", isOn: $showEmptyStations)
                .padding()
            
        }
        .padding(.horizontal)
    }
}
