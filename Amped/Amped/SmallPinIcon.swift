//
//  Legend.swift
//  Amped
//
//  Created by Kevin Choo on 8/15/23.
//

import Foundation
import SwiftUI

struct SmallPinIcon: View {
    
    var body: some View {
        VStack(spacing: 0){
            ZStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 14))
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 9))
                .offset(x: 0, y: -5)
        }
    }
}
