//
//  ContentView.swift
//  Soundia
//
//  Created by Nicholas  on 25/06/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Image(systemName: "sun.min")
                .imageScale(.medium)
                .foregroundStyle(Color.red)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
