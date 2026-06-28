package com.lifetracker.modules.habits.service;

import com.lifetracker.modules.habits.dto.HabitCategoryResponse;
import com.lifetracker.modules.habits.mapper.HabitCategoryMapper;
import com.lifetracker.modules.habits.repository.HabitCategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class HabitCategoryServiceImpl implements HabitCategoryService {
    private final HabitCategoryRepository habitCategoryRepository;
    private final HabitCategoryMapper habitCategoryMapper;

    public HabitCategoryServiceImpl(
            HabitCategoryRepository habitCategoryRepository,
            HabitCategoryMapper habitCategoryMapper
    ) {
        this.habitCategoryRepository = habitCategoryRepository;
        this.habitCategoryMapper = habitCategoryMapper;
    }

    @Override
    public List<HabitCategoryResponse> getAllCategories() {
        return habitCategoryMapper.toResponseList(
                habitCategoryRepository.findAllByActiveTrueOrderByDisplayOrderAscNameAsc()
        );
    }
}
