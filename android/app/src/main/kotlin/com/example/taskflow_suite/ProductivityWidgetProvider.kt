package com.example.taskflow_suite

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ProductivityWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.productivity_widget).apply {
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("taskflow://insights")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_image, pendingIntent)

                val imagePath = widgetData.getString("chart_image", null)
                if (imagePath != null) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.widget_image, bitmap)
                    } else {
                        android.util.Log.e("WidgetProvider", "Failed to decode bitmap at: $imagePath")
                    }
                } else {
                    android.util.Log.w("WidgetProvider", "chart_image path is null in SharedPreferences")
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
