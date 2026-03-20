//
//  JyotiGPTappWidget.swift
//  JyotiGPTappWidget
//
//  Created by y4shg on 07/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct JyotiGPTappEntry: TimelineEntry {
    let date: Date
}

// MARK: - Timeline Provider

struct JyotiGPTappProvider: TimelineProvider {
    func placeholder(in context: Context) -> JyotiGPTappEntry {
        JyotiGPTappEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (JyotiGPTappEntry) -> Void) {
        let entry = JyotiGPTappEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JyotiGPTappEntry>) -> Void) {
        let entry = JyotiGPTappEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Widget View

struct JyotiGPTappWidgetEntryView: View {
    var entry: JyotiGPTappProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    /// Widget accent color aligned with the app's red theme.
    private var accentColor: Color { Color("AccentColor") }

    /// Primary content color when drawn on the accent background.
    private var onAccentColor: Color { .white }

    /// Whether the widget is being rendered in a tint-driven mode.
    private var usesTintedRendering: Bool {
        if #available(iOSApplicationExtension 18.0, *) {
            switch widgetRenderingMode {
            case .accented, .vibrant:
                return true
            default:
                return false
            }
        }

        return false
    }

    /// Adaptive button background based on color scheme and widget mode.
    private var buttonBackground: Color {
        if usesTintedRendering {
            return .accentColor.opacity(colorScheme == .dark ? 0.28 : 0.2)
        }

        return colorScheme == .dark
            ? .white.opacity(0.15)
            : .black.opacity(0.08)
    }

    /// Accent fill that stays visible in tinted and clear widget styles.
    private var primaryFillColor: Color {
        usesTintedRendering ? .accentColor : accentColor
    }

    var body: some View {
        VStack(spacing: 12) {
            // Main "Ask JyotiGPT" pill - ChatGPT style
            Link(destination: URL(string: "jyotigptapp://new_chat?homeWidget=true")!) {
                HStack(spacing: 12) {
                    widgetLogo
                    Text("Ask JyotiGPT")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(onAccentColor.opacity(0.95))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(primaryFillColor)
                        .modifier(WidgetAccentBackgroundModifier())
                )
            }
            .buttonStyle(.plain)

            // 4 circular icon buttons - ChatGPT style, fill width
            HStack(spacing: 8) {
                CircularIconButton(
                    symbol: "camera",
                    url: "jyotigptapp://camera?homeWidget=true",
                    accentColor: primaryFillColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
                CircularIconButton(
                    symbol: "photo.on.rectangle.angled",
                    url: "jyotigptapp://photos?homeWidget=true",
                    accentColor: primaryFillColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
                CircularIconButton(
                    symbol: "waveform",
                    url: "jyotigptapp://mic?homeWidget=true",
                    accentColor: primaryFillColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
                CircularIconButton(
                    symbol: "doc.on.clipboard",
                    url: "jyotigptapp://clipboard?homeWidget=true",
                    accentColor: primaryFillColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
            }
        }
        .padding(16)
    }

    private var widgetLogo: some View {
        Image("WiconIcon")
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
    }
}

// MARK: - Circular Icon Button (ChatGPT Style)

struct CircularIconButton: View {
    let symbol: String
    let url: String
    let accentColor: Color
    let buttonBackground: Color
    let usesTintedRendering: Bool

    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(accentColor.opacity(0.95))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(buttonBackground)
                        .modifier(WidgetAccentBackgroundModifier())
                )
                .modifier(WidgetAccentForegroundModifier(isTinted: usesTintedRendering))
        }
        .buttonStyle(.plain)
    }
}


private struct WidgetAccentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 18.0, *) {
            content.widgetAccentable()
        } else {
            content
        }
    }
}

private struct WidgetAccentForegroundModifier: ViewModifier {
    let isTinted: Bool

    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 18.0, *), isTinted {
            content.foregroundStyle(.white)
        } else {
            content
        }
    }
}

// MARK: - Widget Configuration

struct JyotiGPTappWidget: Widget {
    let kind: String = "JyotiGPTappWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JyotiGPTappProvider()) { entry in
            if #available(iOS 17.0, *) {
                JyotiGPTappWidgetEntryView(entry: entry)
                    .containerBackground(Color("WidgetBackground"), for: .widget)
            } else {
                JyotiGPTappWidgetEntryView(entry: entry)
                    .background(Color("WidgetBackground"))
            }
        }
        .configurationDisplayName("JyotiGPT")
        .description("Quick access to spiritual chat, camera, photos, and voice.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    JyotiGPTappWidget()
} timeline: {
    JyotiGPTappEntry(date: .now)
}
