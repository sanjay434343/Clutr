package com.sas.clutr

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ClutrWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.clutr_widget).apply {
                val spaceToClean = widgetData.getString("space_to_clean", "Ready")
                setTextViewText(R.id.widget_space, spaceToClean)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
