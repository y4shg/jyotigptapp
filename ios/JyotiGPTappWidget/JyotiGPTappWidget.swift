//
//  JyotiGPTappWidget.swift
//  JyotiGPTappWidget
//
//  Created by y4shg on 07/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Actions

struct WidgetQuickAction: Identifiable {
    let id: String
    let title: String
    let shortTitle: String
    let symbol: String
    let url: String
}

extension WidgetQuickAction {
    static let openApp = WidgetQuickAction(
        id: "open",
        title: "Open JyotiGPT",
        shortTitle: "Open",
        symbol: "sparkles",
        url: "jyotigptapp://"
    )

    static let chat = WidgetQuickAction(
        id: "chat",
        title: "New Chat",
        shortTitle: "Chat",
        symbol: "bubble.left.and.bubble.right",
        url: "jyotigptapp://new_chat?homeWidget=true"
    )

    static let voice = WidgetQuickAction(
        id: "voice",
        title: "Voice",
        shortTitle: "Voice",
        symbol: "waveform",
        url: "jyotigptapp://mic?homeWidget=true"
    )

    static let image = WidgetQuickAction(
        id: "image",
        title: "Image",
        shortTitle: "Image",
        symbol: "photo",
        url: "jyotigptapp://photos?homeWidget=true"
    )

    static let smallGrid: [WidgetQuickAction] = [
        .chat,
        .voice,
        .image,
        .openApp,
    ]

    static let accessoryDefaults: [WidgetQuickAction] = [
        .openApp,
        .chat,
        .voice,
        .image,
    ]
}

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
        if #available(iOS 18.0, *) {
            switch widgetRenderingMode {
            case .accented:
                return true
            case .vibrant:
                return false
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
        Group {
            switch family {
            case .systemSmall:
                SmallActionGrid(
                    actions: WidgetQuickAction.smallGrid,
                    accentColor: primaryFillColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
            default:
                MediumActionLayout(
                    accentColor: primaryFillColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
            }
        }
        .padding(16)
    }

    private var widgetLogo: some View {
        Image(decorative: "WiconIcon")
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
    }
}

// MARK: - Small Widget Layout

struct SmallActionGrid: View {
    let actions: [WidgetQuickAction]
    let accentColor: Color
    let buttonBackground: Color
    let usesTintedRendering: Bool

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(actions) { action in
                SquareActionButton(
                    action: action,
                    accentColor: accentColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
            }
        }
    }
}

struct SquareActionButton: View {
    let action: WidgetQuickAction
    let accentColor: Color
    let buttonBackground: Color
    let usesTintedRendering: Bool

    var body: some View {
        Link(destination: URL(string: action.url)!) {
            VStack(spacing: 6) {
                Image(systemName: action.symbol)
                    .font(.system(size: 20, weight: .semibold))
                Text(action.shortTitle)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(accentColor.opacity(0.95))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(buttonBackground)
                    .modifier(WidgetAccentBackgroundModifier())
            )
            .modifier(WidgetAccentForegroundModifier(isTinted: usesTintedRendering))
        }
        .accessibilityLabel(action.title)
        .buttonStyle(.plain)
    }
}

// MARK: - Medium Widget Layout

struct MediumActionLayout: View {
    let accentColor: Color
    let buttonBackground: Color
    let usesTintedRendering: Bool

    var body: some View {
        VStack(spacing: 12) {
            Link(destination: URL(string: WidgetQuickAction.chat.url)!) {
                HStack(spacing: 12) {
                    widgetLogo
                    Text("Ask JyotiGPT")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.95))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(accentColor)
                        .modifier(WidgetAccentBackgroundModifier())
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                CircularIconButton(
                    symbol: "camera",
                    url: "jyotigptapp://camera?homeWidget=true",
                    label: "Open Camera",
                    accentColor: accentColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
                CircularIconButton(
                    symbol: "photo.on.rectangle.angled",
                    url: WidgetQuickAction.image.url,
                    label: "Open Photos",
                    accentColor: accentColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
                CircularIconButton(
                    symbol: WidgetQuickAction.voice.symbol,
                    url: WidgetQuickAction.voice.url,
                    label: "Start Voice",
                    accentColor: accentColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
                CircularIconButton(
                    symbol: "doc.on.clipboard",
                    url: "jyotigptapp://clipboard?homeWidget=true",
                    label: "Paste from Clipboard",
                    accentColor: accentColor,
                    buttonBackground: buttonBackground,
                    usesTintedRendering: usesTintedRendering
                )
            }
        }
    }

    private var widgetLogo: some View {
        Image(decorative: "WiconIcon")
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
    let label: String
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
        .accessibilityLabel(label)
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
        if #available(iOS 18.0, *), isTinted {
            content.foregroundStyle(.white)
        } else {
            content
        }
    }
}

// MARK: - Accessory Widgets

@available(iOS 16.0, *)
struct JyotiGPTAccessoryWidgetEntryView: View {
    let action: WidgetQuickAction
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var usesTintedRendering: Bool {
        if #available(iOS 18.0, *) {
            return widgetRenderingMode == .accented
        }

        return false
    }

    var body: some View {
        Link(destination: URL(string: action.url)!) {
            switch family {
            case .accessoryCircular:
                Image(systemName: action.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .modifier(WidgetAccentForegroundModifier(isTinted: usesTintedRendering))
            case .accessoryInline:
                Label(action.shortTitle, systemImage: action.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .modifier(WidgetAccentForegroundModifier(isTinted: usesTintedRendering))
            case .accessoryRectangular:
                HStack(spacing: 6) {
                    Image(systemName: action.symbol)
                        .font(.system(size: 14, weight: .semibold))
                    Text(action.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .modifier(WidgetAccentForegroundModifier(isTinted: usesTintedRendering))
            default:
                Text(action.shortTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .modifier(WidgetAccentForegroundModifier(isTinted: usesTintedRendering))
            }
        }
        .accessibilityLabel(action.title)
        .buttonStyle(.plain)
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
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

@available(iOS 16.0, *)
struct JyotiGPTAccessoryWidget: Widget {
    let action: WidgetQuickAction

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "JyotiGPTAccessory\(action.id)", provider: JyotiGPTappProvider()) { entry in
            JyotiGPTAccessoryWidgetEntryView(action: action)
        }
        .configurationDisplayName(action.title)
        .description("Open \(action.title.lowercased()) in JyotiGPT.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}

// MARK: - Preview

struct JyotiGPTappWidget_Previews: PreviewProvider {
    static var previews: some View {
        JyotiGPTappWidgetEntryView(entry: JyotiGPTappEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

@available(iOS 16.0, *)
struct JyotiGPTAccessoryWidget_Previews: PreviewProvider {
    static var previews: some View {
        JyotiGPTAccessoryWidgetEntryView(action: .chat)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
