//
//  JyotiGPTappWidgetBundle.swift
//  JyotiGPTappWidget
//
//  Created by y4shg on 07/12/25.
//

import WidgetKit
import SwiftUI

@main
struct JyotiGPTappWidgetBundle: WidgetBundle {
    var body: some Widget {
        JyotiGPTappWidget()
        if #available(iOS 16.0, *) {
            JyotiGPTAccessoryWidget(action: .openApp)
            JyotiGPTAccessoryWidget(action: .chat)
            JyotiGPTAccessoryWidget(action: .voice)
            JyotiGPTAccessoryWidget(action: .image)
        }
    }
}
