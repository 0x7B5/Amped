//
//  PinIcon.swift
//  Amped
//
//  Created by Kevin Choo on 8/15/23.
//

import Foundation
import SwiftUI

struct PinIcon: View {
var numEbikesAvailable: Int

    var body: some View {
        if(numEbikesAvailable == 0){
            VStack(spacing: 0){
                ZStack {
                    Image(systemName: "circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    Text("0")
                        .foregroundColor(.white)
                }
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                    .offset(x: 0, y: -5)
            }
        } else {
            VStack(spacing: 0) {
                ZStack {
                    Image(systemName: "circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text(String(numEbikesAvailable))
                        .foregroundColor(.white)
                }
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .offset(x: 0, y: -5)
            }
        }
    }
}
