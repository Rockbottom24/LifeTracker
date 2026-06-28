package com.lifetracker.modules.settings.service;

import org.springframework.stereotype.Service;

@Service
public class SettingsService {
    public String getStatus() {
        return "Settings module ready";
    }
}
