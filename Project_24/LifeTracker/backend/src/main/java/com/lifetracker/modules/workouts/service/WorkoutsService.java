package com.lifetracker.modules.workouts.service;

import org.springframework.stereotype.Service;

@Service
public class WorkoutsService {
    public String getStatus() {
        return "Workouts module ready";
    }
}
