package com.nickbern.studentsapi.service;

import com.nickbern.studentsapi.dto.CreateStudentRequest;
import com.nickbern.studentsapi.exception.DuplicateEmailException;
import com.nickbern.studentsapi.exception.StudentNotFoundException;
import com.nickbern.studentsapi.model.Student;
import com.nickbern.studentsapi.repository.StudentRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Lógica de negocio: genera el id, normaliza datos y aplica la regla de correo único.
 */
@Service
public class StudentService {

    private final StudentRepository repository;

    public StudentService(StudentRepository repository) {
        this.repository = repository;
    }

    public synchronized Student create(CreateStudentRequest request) {
        String correo = request.correo().trim().toLowerCase();
        if (repository.existsByCorreo(correo)) {
            throw new DuplicateEmailException(correo);
        }

        Student student = new Student(
                UUID.randomUUID(),
                request.nombre().trim(),
                request.apellido().trim(),
                correo,
                Instant.now()
        );
        return repository.save(student);
    }

    public Student findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new StudentNotFoundException(id));
    }

    public List<Student> findAll() {
        return repository.findAll();
    }
}
