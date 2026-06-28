package com.lifetracker.modules.expenses.api;

import com.lifetracker.modules.expenses.dto.CreateExpenseRequest;
import com.lifetracker.modules.expenses.dto.ExpenseDashboardResponse;
import com.lifetracker.modules.expenses.dto.ExpenseResponse;
import com.lifetracker.modules.expenses.dto.UpdateExpenseRequest;
import com.lifetracker.modules.expenses.enums.ExpenseType;
import com.lifetracker.modules.expenses.service.ExpenseService;
import com.lifetracker.shared.application.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Expenses", description = "Expense tracking APIs for the Money module")
@Validated
@RestController
@RequestMapping("/api/v1/expenses")
public class ExpenseController {
    private final ExpenseService expenseService;

    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @Operation(summary = "List all expenses")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Expenses retrieved successfully",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ApiResponse.class),
                            examples = @ExampleObject(name = "Expense list", value = ExpenseOpenApiExamples.LIST_RESPONSE)
                    )
            )
    })
    @GetMapping
    public ResponseEntity<ApiResponse<List<ExpenseResponse>>> getExpenses() {
        return ResponseEntity.ok(
                ApiResponse.success("Expenses retrieved successfully", expenseService.getAllExpenses())
        );
    }

    @Operation(summary = "Get expense dashboard analytics")
    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<ExpenseDashboardResponse>> getDashboard() {
        return ResponseEntity.ok(
                ApiResponse.success("Expense dashboard retrieved successfully", expenseService.getDashboard())
        );
    }

    @Operation(summary = "Get an expense by id")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Expense retrieved successfully",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Single expense", value = ExpenseOpenApiExamples.SUCCESS_RESPONSE)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "404",
                    description = "Expense not found",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Not found", value = ExpenseOpenApiExamples.NOT_FOUND_ERROR)
                    )
            )
    })
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> getExpense(@PathVariable @Positive Long id) {
        return ResponseEntity.ok(
                ApiResponse.success("Expense retrieved successfully", expenseService.getExpenseById(id))
        );
    }

    @Operation(summary = "Create an expense")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "201",
                    description = "Expense created successfully",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Created expense", value = ExpenseOpenApiExamples.SUCCESS_RESPONSE)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "Validation failed",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Validation errors", value = ExpenseOpenApiExamples.VALIDATION_ERROR)
                    )
            )
    })
    @PostMapping
    public ResponseEntity<ApiResponse<ExpenseResponse>> createExpense(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            mediaType = "application/json",
                            examples = {
                                    @ExampleObject(
                                            name = "Personal expense",
                                            value = ExpenseOpenApiExamples.CREATE_PERSONAL
                                    ),
                                    @ExampleObject(
                                            name = "Shared living expense",
                                            value = ExpenseOpenApiExamples.CREATE_SHARED_LIVING
                                    ),
                                    @ExampleObject(
                                            name = "Family expense",
                                            value = ExpenseOpenApiExamples.CREATE_FAMILY
                                    )
                            }
                    )
            )
            @Valid @RequestBody CreateExpenseRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
                ApiResponse.success("Expense created successfully", expenseService.createExpense(request))
        );
    }

    @Operation(summary = "Update an expense")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Expense updated successfully",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Updated expense", value = ExpenseOpenApiExamples.SUCCESS_RESPONSE)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "Validation failed",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Validation errors", value = ExpenseOpenApiExamples.VALIDATION_ERROR)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "404",
                    description = "Expense not found",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Not found", value = ExpenseOpenApiExamples.NOT_FOUND_ERROR)
                    )
            )
    })
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> updateExpense(
            @PathVariable @Positive Long id,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Update expense", value = ExpenseOpenApiExamples.UPDATE)
                    )
            )
            @Valid @RequestBody UpdateExpenseRequest request
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Expense updated successfully", expenseService.updateExpense(id, request))
        );
    }

    @Operation(summary = "Delete an expense")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "204",
                    description = "Expense deleted successfully"
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "404",
                    description = "Expense not found",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(name = "Not found", value = ExpenseOpenApiExamples.NOT_FOUND_ERROR)
                    )
            )
    })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteExpense(@PathVariable @Positive Long id) {
        expenseService.deleteExpense(id);
        return ResponseEntity.noContent().build();
    }
}
