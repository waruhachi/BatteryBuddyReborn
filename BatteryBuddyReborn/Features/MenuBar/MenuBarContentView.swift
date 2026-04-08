//
//  MenuBarContentView.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.headlineText)
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()

            Text(model.detailText)
                .foregroundStyle(.secondary)
                .font(.system(size: 11, weight: .regular))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 190, alignment: .leading)
    }
}
