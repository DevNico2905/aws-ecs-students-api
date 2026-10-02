package com.nickbern.studentsapi.repository;

import com.nickbern.studentsapi.model.Student;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Contrato de persistencia. Hoy lo implementa una estructura en memoria;
 * cambiar a DynamoDB o RDS solo requiere otra implementación de esta interfaz.
 */
public interface StudentRepository {

    Student save(Student student);

    Optional<Student> findById(UUID id);

    List<Student> findAll();

    boolean existsByCorreo(String correo);
}
