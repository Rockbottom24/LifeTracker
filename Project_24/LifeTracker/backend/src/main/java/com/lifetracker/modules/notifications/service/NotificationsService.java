package com.lifetracker.modules.notifications.service;

import org.springframework.stereotype.Service;

@Service
public class NotificationsService {
    public String getStatus() {
        return "Notifications module ready";
    }
}
