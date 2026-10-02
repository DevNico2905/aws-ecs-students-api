package com.nickbern.studentsapi.repository;

import com.nickbern.studentsapi.model.Student;
import org.springframework.stereotype.Repository;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Almacenamiento en memoria. ConcurrentHashMap porque Tomcat atiende peticiones
 * en varios hilos a la vez. Los datos viven mientras viva el contenedor.
 */
@Repository
public class InMemoryStudentRepository implements StudentRepository {

    private final Map<UUID, Student> students = new ConcurrentHashMap<>();

    @Override
    public Student save(Student student) {
        students.put(student.id(), student);
        return student;
    }

    @Override
    public Optional<Student> findById(UUID id) {
        return Optional.ofNullable(students.get(id));
    }

    @Override
    public List<Student> findAll() {
        return students.values().stream()
                .sorted(Comparator.comparing(Student::fechaCreacion))
                .toList();
    }

    @Override
    public boolean existsByCorreo(String correo) {
        return students.values().stream()
                .anyMatch(s -> s.correo().equalsIgnoreCase(correo));
    }
}
