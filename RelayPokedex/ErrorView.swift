//
//  ErrorView.swift
//  RelayTestApp
//
//  Created by Matt Moriarity on 5/3/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    let error: Error

    var body: some View {
        Text(error.localizedDescription)
            .foregroundColor(.red)
    }
}
