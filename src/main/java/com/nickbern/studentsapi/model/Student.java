package com.nickbern.studentsapi.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Entidad de dominio. Es un record: inmutable y sin boilerplate (getters, equals, hashCode).
 */
public record Student(
        UUID id,
        String nombre,
        String apellido,
        String correo,
        Instant fechaCreacion
) {
}
