//
//  Testing .swift
//  MasteringNetworkingUsingURLSession
//
//  Created by Tech Exactly iPhone 6 on 05/02/25.
//

import SwiftUI

struct Testing_: View {
    @State private var items = Array(0..<10)

    var body: some View {
        NavigationStack{
            List {
                ForEach(items, id: \.self) { item in
                    VStack{
                        Text("Hello world")
                        Text("Tech Exactly")
                    }
                }.onDelete(perform: deleteItems)
            }
        }
    }
    // Function to handle deletion of items
        private func deleteItems(at offsets: IndexSet) {
            items.remove(atOffsets: offsets)
        }
}

struct Testing__Previews: PreviewProvider {
    static var previews: some View {
        Testing_()
    }
}
