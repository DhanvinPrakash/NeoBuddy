//
//  ProtocolImage.swift
//  kkhs2
//
//  Created by dhanvin_macbook on 24/9/26.
//


//
//  ProtocolImages.swift
//  kkhs2
//
//  Pictures shown inside a condition's "NICU Protocol" card (flowcharts,
//  score tables). Tap an image to open a pinch-to-zoom viewer.
//
//  To add a picture: drop the PNG into Assets.xcassets, then add its asset
//  name to `protocolImages(for:)` below. Images whose asset is missing are
//  skipped silently, so the app never shows a broken/blank box.
//
//    NICU_cooling_criteria  – "Suspected Asphyxia: Do you need to cool?" flowchart
//    NICU_thompson_table    – Thompson score table (baseline, before cooling)
//

import SwiftUI
import UIKit

struct ProtocolImage: Identifiable {
    let assetName: String
    let caption: String
    var id: String { assetName }
    var isAvailable: Bool { UIImage(named: assetName) != nil }
}

func protocolImages(for conditionName: String) -> [ProtocolImage] {
    let name = conditionName.lowercased()
    var images: [ProtocolImage] = []

    if name.contains("hypoxic") || name.contains("hie") {
        images.append(ProtocolImage(assetName: "NICU_cooling_criteria",
                                    caption: "Suspected asphyxia — do you need to cool?"))
        images.append(ProtocolImage(assetName: "NICU_thompson_table",
                                    caption: "Thompson score at baseline (before cooling)"))
    }
    return images.filter(\.isAvailable)
}

struct ProtocolImageCard: View {
    let image: ProtocolImage
    @State private var showViewer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                Haptics.checklistTap()
                showViewer = true
            } label: {
                Image(image.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)               // charts are black-on-white; keep readable in dark mode
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption.bold())
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(6)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(image.caption). Tap to enlarge.")

            Text(image.caption)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .fullScreenCover(isPresented: $showViewer) {
            ZoomableImageViewer(image: image)
        }
    }
}

private struct ZoomableImageViewer: View {
    let image: ProtocolImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(image.assetName)
                        .resizable()
                        .scaledToFit()
                        .background(Color.white)
                        .frame(width: geo.size.width * scale, height: geo.size.height * scale)
                        .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in scale = min(5, max(1, lastScale * value)) }
                        .onEnded { _ in lastScale = scale }
                )
                .onTapGesture(count: 2) {
                    withAnimation { scale = scale > 1 ? 1 : 2.5; lastScale = scale }
                }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.9))
                    .padding()
            }
            .accessibilityLabel("Close image")
        }
    }
}