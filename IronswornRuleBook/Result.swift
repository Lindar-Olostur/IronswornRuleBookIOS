//
//  Result.swift
//  IronswornRuleBook
//
//  Created by Lindar Olostur on 16.04.2022.
//

import SwiftUI

struct Result: View {
    @State var result = 100
    var body: some View {
        
        Text("\(result)")
            .frame(width: 80, height: 50, alignment: .center)
            .font(.largeTitle)
            .foregroundColor(.white)
            .background(Color.gray)
            .clipShape(Capsule())
    }
}

struct Result_Previews: PreviewProvider {
    static var previews: some View {
        Result()
    }
}
