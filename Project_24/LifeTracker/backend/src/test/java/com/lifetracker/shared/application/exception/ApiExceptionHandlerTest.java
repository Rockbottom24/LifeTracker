package com.lifetracker.shared.application.exception;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ApiExceptionHandlerTest {

    private final ApiExceptionHandler handler = new ApiExceptionHandler();

    @Test
    void handleResponseStatus_returnsMatchingHttpStatus() {
        ResponseStatusException ex = new ResponseStatusException(HttpStatus.NOT_FOUND, "Habit not found");

        ResponseEntity<Map<String, String>> response = handler.handleResponseStatus(ex);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        assertEquals("Habit not found", response.getBody().get("error"));
    }

    @Test
    void handleUnreadableMessage_returnsBadRequest() {
        ResponseEntity<Map<String, String>> response = handler.handleUnreadableMessage(
                new org.springframework.http.converter.HttpMessageNotReadableException("bad json", null, null)
        );

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("Malformed JSON request body.", response.getBody().get("error"));
    }
}
