//
//  LoadingView.swift
//  RelayStarWars
//
//  Created by Matt Moriarity on 5/8/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ActivityIndicator(isAnimating: .constant(true), style: .large)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}

private struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
