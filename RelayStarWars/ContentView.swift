//
//  ContentView.swift
//  RelayStarWars
//
//  Created by Matt Moriarity on 5/8/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
 
    var body: some View {
        TabView(selection: $selection){
            MoviesTab()
                .tabItem {
                    VStack {
                        Image("first")
                        Text("Movies")
                    }
                }
                .tag(0)
            Text("Second View")
                .font(.title)
                .tabItem {
                    VStack {
                        Image("second")
                        Text("Second")
                    }
                }
                .tag(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
