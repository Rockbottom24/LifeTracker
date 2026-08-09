package com.lifetracker.modules.workouts.dto;

import java.time.LocalDate;
import java.util.List;

public record ApplyTemplateRequest(
        LocalDate startDate,
        List<Long> templateIdsInOrder // Order of workout templates for the cycle loop
) {}
