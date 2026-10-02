package com.nickbern.studentsapi.dto;

import com.nickbern.studentsapi.model.Student;

import java.time.Instant;
import java.util.UUID;

/**
 * Representación JSON que devuelve la API. Separar DTO y entidad evita exponer
 * el modelo interno si mañana cambia (por ejemplo, al migrar a una base de datos).
 */
public record StudentResponse(
        UUID id,
        String nombre,
        String apellido,
        String correo,
        Instant fechaCreacion
) {
    public static StudentResponse from(Student student) {
        return new StudentResponse(
                student.id(),
                student.nombre(),
                student.apellido(),
                student.correo(),
                student.fechaCreacion()
        );
    }
}
