package com.example.taskflow_suite

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TaskDeadlineWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                updateAppWidget(context, appWidgetManager, widgetId, widgetData)
            } catch (e: Exception) {
                Log.e("TaskDeadlineWidget", "Error updating widget $widgetId", e)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            updateAppWidget(context, appWidgetManager, appWidgetId, prefs)
        } catch (e: Exception) {
            Log.e("TaskDeadlineWidget", "Error on options changed $appWidgetId", e)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_task_deadline_1x2)

        val title = widgetData.getString("flutter.deadline_task_title", null)
            ?: widgetData.getString("deadline_task_title", null)
            ?: "Scheduled Task"

        val emoji = widgetData.getString("flutter.deadline_task_emoji", null)
            ?: widgetData.getString("deadline_task_emoji", null)
            ?: "🎯"

        val daysNum = widgetData.getString("flutter.deadline_days_num", null)
            ?: widgetData.getString("deadline_days_num", null)
            ?: "--"

        val daysUnit = widgetData.getString("flutter.deadline_days_unit", null)
            ?: widgetData.getString("deadline_days_unit", null)
            ?: "days left"

        val hideTaskName = widgetData.getBoolean("flutter.hide_countdown_task_name", false)
            || widgetData.getBoolean("hide_countdown_task_name", false)

        try {
            if (hideTaskName) {
                views.setViewVisibility(R.id.text_deadline_title, View.GONE)
            } else {
                views.setViewVisibility(R.id.text_deadline_title, View.VISIBLE)
                views.setTextViewText(R.id.text_deadline_title, title)
            }
            views.setTextViewText(R.id.text_deadline_emoji, emoji)
            views.setTextViewText(R.id.text_deadline_days_num, daysNum)
            views.setTextViewText(R.id.text_deadline_days_unit, daysUnit)
        } catch (e: Exception) {
            Log.e("TaskDeadlineWidget", "Error setting widget views", e)
        }

        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("taskflow://calendar")
        )

        try {
            views.setOnClickPendingIntent(R.id.widget_deadline_container, launchIntent)
        } catch (e: Exception) {
            Log.e("TaskDeadlineWidget", "Error setting click listeners", e)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
