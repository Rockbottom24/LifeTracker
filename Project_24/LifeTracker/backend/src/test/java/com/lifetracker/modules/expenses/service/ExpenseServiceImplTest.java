package com.lifetracker.modules.expenses.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.expenses.dto.CreateExpenseRequest;
import com.lifetracker.modules.expenses.dto.UpdateExpenseRequest;
import com.lifetracker.modules.expenses.entity.Expense;
import com.lifetracker.modules.expenses.enums.ExpenseType;
import com.lifetracker.modules.expenses.mapper.ExpenseMapper;
import com.lifetracker.modules.expenses.repository.ExpenseRepository;
import com.lifetracker.shared.application.exception.ApiExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExpenseServiceImplTest {

    @Mock
    private ExpenseRepository expenseRepository;

    @Mock
    private ExpenseDashboardBuilder expenseDashboardBuilder;

    @Mock
    private CurrentUserService currentUserService;

    private ExpenseServiceImpl expenseService;

    @BeforeEach
    void setUp() {
        when(currentUserService.getCurrentUserId()).thenReturn(1L);
        expenseService = new ExpenseServiceImpl(
                expenseRepository,
                new ExpenseMapper(),
                expenseDashboardBuilder,
                currentUserService
        );
    }

    @Test
    void createExpense_generatesUuidBeforeSave() {
        CreateExpenseRequest request = sampleCreateRequest();
        when(expenseRepository.save(any(Expense.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var response = expenseService.createExpense(request);

        ArgumentCaptor<Expense> captor = ArgumentCaptor.forClass(Expense.class);
        verify(expenseRepository).save(captor.capture());
        Expense saved = captor.getValue();

        assertNotNull(saved.getUuid());
        assertEquals(saved.getUuid(), response.uuid());
        assertEquals("Groceries", response.category());
    }

    @Test
    void getExpenseById_throwsNotFoundWhenMissing() {
        when(expenseRepository.findByIdAndUserId(404L, 1L)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(
                ResponseStatusException.class,
                () -> expenseService.getExpenseById(404L)
        );

        assertEquals(404, ex.getStatusCode().value());
        assertEquals("Expense not found", ex.getReason());
    }

    @Test
    void updateExpense_updatesExistingRecord() {
        Expense existing = persistedExpense(2L);
        UpdateExpenseRequest request = new UpdateExpenseRequest(
                ExpenseType.FAMILY,
                "Healthcare",
                "Doctor visit",
                "Updated note",
                new BigDecimal("1600.00"),
                LocalDate.of(2026, 6, 21),
                "Cash",
                "Follow-up"
        );

        when(expenseRepository.findByIdAndUserId(2L, 1L)).thenReturn(Optional.of(existing));
        when(expenseRepository.saveAndFlush(any(Expense.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var response = expenseService.updateExpense(2L, request);

        assertEquals("Doctor visit", response.title());
        assertEquals(ExpenseType.FAMILY, response.expenseType());
        assertEquals(new BigDecimal("1600.00"), response.amount());
    }

    private CreateExpenseRequest sampleCreateRequest() {
        return new CreateExpenseRequest(
                ExpenseType.PERSONAL,
                "Groceries",
                "Weekly supermarket run",
                "Pantry items",
                new BigDecimal("87.50"),
                LocalDate.of(2026, 6, 27),
                "UPI",
                "Paid via PhonePe"
        );
    }

    private Expense persistedExpense(Long id) {
        Expense expense = new Expense();
        expense.setUuid(UUID.randomUUID());
        expense.setUserId(1L);
        expense.setExpenseType(ExpenseType.PERSONAL);
        expense.setCategory("Groceries");
        expense.setTitle("Weekly supermarket run");
        expense.setAmount(new BigDecimal("87.50"));
        expense.setExpenseDate(LocalDate.of(2026, 6, 27));
        return expense;
    }
}
