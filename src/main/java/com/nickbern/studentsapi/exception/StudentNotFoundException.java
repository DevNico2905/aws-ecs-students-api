package com.nickbern.studentsapi.exception;

import java.util.UUID;

public class StudentNotFoundException extends RuntimeException {

    public StudentNotFoundException(UUID id) {
        super("No existe un estudiante con id " + id);
    }
}
