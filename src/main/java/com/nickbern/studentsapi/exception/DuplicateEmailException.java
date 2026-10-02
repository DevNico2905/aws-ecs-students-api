package com.nickbern.studentsapi.exception;

public class DuplicateEmailException extends RuntimeException {

    public DuplicateEmailException(String correo) {
        super("Ya existe un estudiante registrado con el correo " + correo);
    }
}
