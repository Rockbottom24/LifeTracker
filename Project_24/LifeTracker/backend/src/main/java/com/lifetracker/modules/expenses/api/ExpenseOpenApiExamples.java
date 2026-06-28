package com.lifetracker.modules.expenses.api;

public final class ExpenseOpenApiExamples {
    private ExpenseOpenApiExamples() {
    }

    public static final String CREATE_PERSONAL = """
            {
              "expenseType": "PERSONAL",
              "category": "Groceries",
              "title": "Weekly supermarket run",
              "description": "Fruits, vegetables, and pantry staples",
              "amount": 87.50,
              "expenseDate": "2026-06-27",
              "paymentMode": "UPI",
              "notes": "Paid via PhonePe"
            }
            """;

    public static final String CREATE_SHARED_LIVING = """
            {
              "expenseType": "SHARED_LIVING",
              "category": "Utilities",
              "title": "Electricity bill",
              "description": "June electricity for flatmates",
              "amount": 2400.00,
              "expenseDate": "2026-06-25",
              "paymentMode": "Bank Transfer",
              "notes": "Split among 3 roommates"
            }
            """;

    public static final String CREATE_FAMILY = """
            {
              "expenseType": "FAMILY",
              "category": "Healthcare",
              "title": "Doctor visit",
              "description": "Annual check-up",
              "amount": 1500.00,
              "expenseDate": "2026-06-20",
              "paymentMode": "Cash",
              "notes": null
            }
            """;

    public static final String UPDATE = """
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

    public static final String SUCCESS_RESPONSE = """
            {
              "success": true,
              "message": "Expense retrieved successfully",
              "data": {
                "id": 1,
                "uuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                "expenseType": "PERSONAL",
                "category": "Groceries",
                "title": "Weekly supermarket run",
                "description": "Fruits, vegetables, and pantry staples",
                "amount": 87.50,
                "expenseDate": "2026-06-27",
                "paymentMode": "UPI",
                "notes": "Paid via PhonePe"
              },
              "timestamp": "2026-06-27T12:00:00Z"
            }
            """;

    public static final String LIST_RESPONSE = """
            {
              "success": true,
              "message": "Expenses retrieved successfully",
              "data": [
                {
                  "id": 1,
                  "uuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                  "expenseType": "PERSONAL",
                  "category": "Groceries",
                  "title": "Weekly supermarket run",
                  "description": "Fruits, vegetables, and pantry staples",
                  "amount": 87.50,
                  "expenseDate": "2026-06-27",
                  "paymentMode": "UPI",
                  "notes": "Paid via PhonePe"
                }
              ],
              "timestamp": "2026-06-27T12:00:00Z"
            }
            """;

    public static final String VALIDATION_ERROR = """
            {
              "title": "must not be blank",
              "amount": "must be greater than or equal to 0.01",
              "category": "must not be blank",
              "expenseDate": "must not be null",
              "expenseType": "must not be null"
            }
            """;

    public static final String NOT_FOUND_ERROR = """
            {
              "error": "Expense not found"
            }
            """;
}