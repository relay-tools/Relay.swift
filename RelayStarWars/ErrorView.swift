//
//  ErrorView.swift
//  RelayStarWars
//
//  Created by Matt Moriarity on 5/8/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import Foundation
import SwiftUI

struct ErrorView: View {
    let error: Error

    var body: some View {
        VStack {
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.red)
            if error is LocalizedError {
                if (error as! LocalizedError).failureReason != nil {
                    Text((error as! LocalizedError).failureReason!)
                        .font(.body)
                        .foregroundColor(.red)
                }
            }
        }
    }
}
