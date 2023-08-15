//
//  StationInfo.swift
//  Amped
//
//  Created by Kevin Choo & Vlad Munteanu on 8/15/23.
//

import Foundation
import SwiftUI


struct StationInfo: View {
    
    var currentStation: Station
    @Binding var walkingTime: TimeInterval?
    @Binding var isStationSheetVisible: Bool
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                Text(currentStation.stationName)
                    .fontWeight(.bold)
                    .font(.title)
                    .padding(.top)
                    .multilineTextAlignment(.center)
                HStack {
                    Spacer()
                    Image(systemName: "x.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title)
                        .onTapGesture {
                            isStationSheetVisible = false
                        }
                        .offset(x: -10, y: -20)
                }
            }
            HStack {
                VStack {
                    HStack {
                        Image(systemName: "bicycle")
                            .font(.title)
                        Text(String(currentStation.ebikesAvailable))
                            .font(.title)
                    }
                    Text("ebikes")
                        .font(.caption)
                }
                Divider()
                    .frame(width: 4)
                    .frame(height: 50)
                    .padding()
                VStack {
                    HStack {
                        Image(systemName: "figure.walk")
                            .font(.title)
                        Text(walkingTime.map { formatTime(TimeInterval($0))}  ?? "unknown")
                            .font(.title)
                    }
                    Text("minutes")
                        .font(.caption)
                }
            }
            Button {
                openDirections(currentStation: currentStation)
            } label: {
                Text("Get Directions").bold()
            }
            .buttonStyle(DirectionsButton())
        }
    }
}

struct DirectionsButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
    }
}
