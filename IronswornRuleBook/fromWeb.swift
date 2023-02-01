//
//  fromWeb.swift
//  IronswornRuleBook
//
//  Created by Lindar Olostur on 13.04.2022.
//

import SwiftUI
import WebKit
 
struct Webview: UIViewRepresentable {
 
    var url: URL
 
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
 
    func updateUIView(_ webview: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webview.load(request)
    }
}


struct fromWeb: View {
    var body: some View {
        Webview(url: URL(string: "http://www.google.com")!)
    }
}

struct fromWeb_Previews: PreviewProvider {
    static var previews: some View {
        fromWeb()
    }
}
