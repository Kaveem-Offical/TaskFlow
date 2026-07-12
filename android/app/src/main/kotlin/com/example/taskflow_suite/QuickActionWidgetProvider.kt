package com.example.taskflow_suite

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickActionWidgetProvider : HomeWidgetProvider() {

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
                Log.e("QuickActionWidget", "Error updating widget $widgetId", e)
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
            Log.e("QuickActionWidget", "Error on options changed $appWidgetId", e)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 140)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 140)

        // Select layout dynamically based on launcher grid size: 1X1, 1X2, 2X2, 2X4
        val layoutId = when {
            minWidth < 105 && minHeight < 105 -> R.layout.widget_quick_action_1x1 // 1X1
            minWidth >= 105 && minHeight < 105 -> R.layout.widget_quick_action_1x2 // 1X2 horizontal
            minWidth >= 210 || minHeight >= 210 -> R.layout.widget_quick_action_2x4 // 2X4 expanded
            else -> R.layout.widget_quick_action_2x2 // 2X2 square
        }

        val views = RemoteViews(context.packageName, layoutId)

        // Retrieve dynamic status from Flutter SharedPreferences
        val pomodoroStatus = widgetData.getString("flutter.pomodoro_status", null)
            ?: widgetData.getString("pomodoro_status", null)
            ?: "25:00 Focus Ready"
        val taskSummary = widgetData.getString("flutter.task_count_summary", null)
            ?: widgetData.getString("task_count_summary", null)
            ?: "+ Tap to Quick Add Task"

        // Populate text based on selected layout
        try {
            when (layoutId) {
                R.layout.widget_quick_action_1x2 -> {
                    val cleanStatus = if (pomodoroStatus.contains("25:00")) "25:00" else pomodoroStatus
                    views.setTextViewText(R.id.text_pomodoro_status_1x2, cleanStatus)
                }
                R.layout.widget_quick_action_2x2 -> {
                    val cleanStatus = if (pomodoroStatus.contains("25:00")) "25:00" else pomodoroStatus
                    views.setTextViewText(R.id.text_pomodoro_status_2x2, cleanStatus)
                    views.setTextViewText(R.id.text_task_count_2x2, "New")
                }
                R.layout.widget_quick_action_2x4 -> {
                    val cleanStatus = if (pomodoroStatus.contains("25:00")) "25:00" else pomodoroStatus
                    views.setTextViewText(R.id.text_pomodoro_status_2x4, cleanStatus)
                    views.setTextViewText(R.id.text_task_count_2x4, "Tap to create instantly")
                }
            }
        } catch (e: Exception) {
            Log.e("QuickActionWidget", "Error setting text views", e)
        }

        // PendingIntent for Quick Pomodoro -> launches Pomodoro/Focus Screen
        val focusIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("taskflow://focus")
        )

        // PendingIntent for Quick Add Task -> launches Quick Add Task modal
        val addTaskIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("taskflow://add_task")
        )

        // Attach click listeners
        try {
            when (layoutId) {
                R.layout.widget_quick_action_1x1 -> {
                    views.setOnClickPendingIntent(R.id.btn_pomodoro_1x1, focusIntent)
                    views.setOnClickPendingIntent(R.id.btn_add_task_1x1, addTaskIntent)
                }
                R.layout.widget_quick_action_1x2 -> {
                    views.setOnClickPendingIntent(R.id.btn_pomodoro_1x2, focusIntent)
                    views.setOnClickPendingIntent(R.id.btn_add_task_1x2, addTaskIntent)
                }
                R.layout.widget_quick_action_2x2 -> {
                    views.setOnClickPendingIntent(R.id.btn_pomodoro_2x2, focusIntent)
                    views.setOnClickPendingIntent(R.id.btn_add_task_2x2, addTaskIntent)
                }
                R.layout.widget_quick_action_2x4 -> {
                    views.setOnClickPendingIntent(R.id.btn_pomodoro_2x4, focusIntent)
                    views.setOnClickPendingIntent(R.id.btn_add_task_2x4, addTaskIntent)
                }
            }
        } catch (e: Exception) {
            Log.e("QuickActionWidget", "Error setting click listeners", e)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
