import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct BalanceHorizonWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        WeekBalanceWidget()
    }
}

// MARK: - Small Balance Widget

struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BalanceWidgetIntent.self,
            provider: BalanceWidgetProvider()
        ) { entry in
            SmallBalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Balance")
        .description("See your projected balance for today at a glance.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

// MARK: - Medium Week Balance Widget

struct WeekBalanceWidget: Widget {
    let kind: String = "WeekBalanceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BalanceWidgetIntent.self,
            provider: BalanceWidgetProvider()
        ) { entry in
            MediumBalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("7-Day Forecast")
        .description("View your projected balance for the next 7 days.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
