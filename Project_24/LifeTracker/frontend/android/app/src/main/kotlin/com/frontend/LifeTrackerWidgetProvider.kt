package com.frontend

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews

class LifeTrackerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val TAG = "LifeTrackerWidget"

        private fun getIntSafe(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
            return try {
                if (!prefs.contains(key)) return defaultVal
                val obj = prefs.all[key]
                when (obj) {
                    is Long -> obj.toInt()
                    is Int -> obj
                    is String -> obj.toIntOrNull() ?: defaultVal
                    else -> defaultVal
                }
            } catch (e: Exception) {
                defaultVal
            }
        }

        private fun getStringSafe(prefs: SharedPreferences, vararg keys: String, defaultVal: String): String {
            for (k in keys) {
                if (prefs.contains(k)) {
                    val valStr = prefs.getString(k, null)
                    if (!valStr.isNullOrEmpty()) return valStr
                }
            }
            return defaultVal
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                val houseKey = getStringSafe(
                    prefs,
                    "flutter.widget_house_key",
                    "flutter.user_house_key",
                    "widget_house_key",
                    "user_house_key",
                    defaultVal = "stark"
                )

                val completed = getIntSafe(prefs, "flutter.widget_completed_quests", 0)
                val total = getIntSafe(prefs, "flutter.widget_total_quests", 0)
                val streak = getIntSafe(prefs, "flutter.widget_current_streak", 1)
                val workoutName = getStringSafe(prefs, "flutter.widget_workout_name", defaultVal = "Rest Day 🛡️")
                val nutritionText = getStringSafe(prefs, "flutter.widget_calories_text", defaultVal = "Log Meals 🍎")

                val (sigil, houseName, bgColor, accentColor) = when (houseKey.lowercase()) {
                    "targaryen" -> Tuple4("🐉", "Targaryen", "#240A0D", "#FF5252")
                    "lannister" -> Tuple4("🦁", "Lannister", "#2A1608", "#FFD700")
                    "baratheon" -> Tuple4("🦌", "Baratheon", "#221C08", "#FFB300")
                    "tyrell" -> Tuple4("🌹", "Tyrell", "#092011", "#81C784")
                    "martell" -> Tuple4("☀️", "Martell", "#241208", "#FF8A65")
                    "arryn" -> Tuple4("🦅", "Arryn", "#0A1624", "#64B5F6")
                    "greyjoy" -> Tuple4("🦑", "Greyjoy", "#10161D", "#90A4AE")
                    else -> Tuple4("🐺", "House Stark", "#121820", "#C4B28B")
                }

                val views = RemoteViews(context.packageName, R.layout.widget_life_tracker)

                // Set House Background Color
                views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor(bgColor))

                views.setTextViewText(R.id.widget_house_sigil, sigil)
                views.setTextViewText(R.id.widget_house_name, houseName)
                views.setTextColor(R.id.widget_house_name, Color.parseColor(accentColor))
                views.setTextViewText(R.id.widget_streak_text, "🔥 ${streak}d")

                val pct = if (total > 0) (completed * 100 / total) else 0
                views.setTextViewText(R.id.widget_quest_status, "$completed/$total ($pct%)")
                views.setTextColor(R.id.widget_quest_status, Color.parseColor(accentColor))
                views.setProgressBar(R.id.widget_progress_bar, 100, pct, false)

                views.setTextViewText(R.id.widget_workout_text, workoutName)
                views.setTextViewText(R.id.widget_nutrition_text, nutritionText)

                // Intent to open MainActivity when widget is tapped
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update widget: $e", e)
            }
        }

        fun sendUpdateBroadcast(context: Context) {
            try {
                val intent = Intent(context, LifeTrackerWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                }
                val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(
                    ComponentName(context, LifeTrackerWidgetProvider::class.java)
                )
                intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                context.sendBroadcast(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send update broadcast: $e", e)
            }
        }
    }
}

private data class Tuple4<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)
