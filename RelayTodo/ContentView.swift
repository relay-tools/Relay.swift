//
//  ContentView.swift
//  RelayTodo
//
//  Created by Matt Moriarity on 5/18/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            CurrentUserToDoList()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
