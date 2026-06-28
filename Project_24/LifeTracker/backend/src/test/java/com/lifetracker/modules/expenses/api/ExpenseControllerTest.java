package com.lifetracker.modules.expenses.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.lifetracker.modules.auth.security.JwtService;
import com.lifetracker.modules.expenses.dto.ComparisonMetric;
import com.lifetracker.modules.expenses.dto.ExpenseDashboardResponse;
import com.lifetracker.modules.expenses.dto.ExpenseResponse;
import com.lifetracker.modules.expenses.dto.MonthlyComparison;
import com.lifetracker.modules.expenses.enums.ExpenseType;
import com.lifetracker.modules.expenses.service.ExpenseService;
import com.lifetracker.shared.application.exception.ApiExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ExpenseController.class, excludeAutoConfiguration = SecurityAutoConfiguration.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(ApiExceptionHandler.class)
class ExpenseControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ExpenseService expenseService;

    @MockBean
    private JwtService jwtService;

    @Test
    void createExpense_returns201() throws Exception {
        ExpenseResponse response = sampleResponse();
        when(expenseService.createExpense(any())).thenReturn(response);

        mockMvc.perform(post("/api/v1/expenses")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validCreateJson()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.title").value("Weekly supermarket run"));
    }

    @Test
    void createExpense_returns400WhenRequiredFieldsMissing() throws Exception {
        mockMvc.perform(post("/api/v1/expenses")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "amount": 0
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").exists())
                .andExpect(jsonPath("$.category").exists())
                .andExpect(jsonPath("$.expenseDate").exists())
                .andExpect(jsonPath("$.expenseType").exists());
    }

    @Test
    void getExpenses_returns200() throws Exception {
        when(expenseService.getAllExpenses()).thenReturn(List.of(sampleResponse()));

        mockMvc.perform(get("/api/v1/expenses"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(1));
    }

    @Test
    void getDashboard_returns200() throws Exception {
        when(expenseService.getDashboard()).thenReturn(sampleDashboard());

        mockMvc.perform(get("/api/v1/expenses/dashboard"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalSpentThisMonth").value(1000));
    }

    @Test
    void getExpenseById_returns404WhenMissing() throws Exception {
        when(expenseService.getExpenseById(99L))
                .thenThrow(new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Expense not found"));

        mockMvc.perform(get("/api/v1/expenses/99"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Expense not found"));
    }

    @Test
    void updateExpense_returns200() throws Exception {
        when(expenseService.updateExpense(eq(1L), any())).thenReturn(sampleResponse());

        mockMvc.perform(put("/api/v1/expenses/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validUpdateJson()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Expense updated successfully"));
    }

    @Test
    void deleteExpense_returns204() throws Exception {
        doNothing().when(expenseService).deleteExpense(1L);

        mockMvc.perform(delete("/api/v1/expenses/1"))
                .andExpect(status().isNoContent());
    }

    @Test
    void deleteExpense_returns404WhenMissing() throws Exception {
        doThrow(new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Expense not found"))
                .when(expenseService).deleteExpense(404L);

        mockMvc.perform(delete("/api/v1/expenses/404"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Expense not found"));
    }

    @Test
    void createExpense_returns400ForMalformedJson() throws Exception {
        mockMvc.perform(post("/api/v1/expenses")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ invalid json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Malformed JSON request body."));
    }

    private ExpenseDashboardResponse sampleDashboard() {
        ComparisonMetric metric = new ComparisonMetric(
                new BigDecimal("1000.00"),
                new BigDecimal("800.00"),
                new BigDecimal("200.00"),
                25.0
        );
        return new ExpenseDashboardResponse(
                new BigDecimal("1000.00"),
                new BigDecimal("500.00"),
                new BigDecimal("300.00"),
                new BigDecimal("200.00"),
                List.of(),
                List.of(),
                List.of(sampleResponse()),
                List.of(),
                new MonthlyComparison(metric, metric, metric, metric)
        );
    }

    private ExpenseResponse sampleResponse() {
        return new ExpenseResponse(
                1L,
                UUID.fromString("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
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

    private String validCreateJson() {
        return """
                {
                  "expenseType": "PERSONAL",
                  "category": "Groceries",
                  "title": "Weekly supermarket run",
                  "description": "Pantry items",
                  "amount": 87.50,
                  "expenseDate": "2026-06-27",
                  "paymentMode": "UPI",
                  "notes": "Paid via PhonePe"
                }
                """;
    }

    private String validUpdateJson() {
        return """
                {
                  "expenseType": "PERSONAL",
                  "category": "Groceries",
                  "title": "Weekly supermarket run (updated)",
                  "description": "Added snacks",
                  "amount": 95.00,
                  "expenseDate": "2026-06-27",
                  "paymentMode": "Credit Card",
                  "notes": "Corrected amount"
                }
                """;
    }
}
