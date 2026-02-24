//
//  ContentView.swift
//  Epilepsia APP
//
//  Created by Macbook Pro on 16/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // Query left here in case we need SwiftData later, but unused for now
    @Query private var items: [Item]

    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                // Intro Splash
                ZStack {
                    LinearGradient(colors: [Color(hex: "050510"), Color.black], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    
                    VStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.blue.opacity(0.8))
                            .shadow(color: .blue, radius: 20)
                        
                        Text("ICTAL")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSplash = false
                        }
                    }
                }
            } else {
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
