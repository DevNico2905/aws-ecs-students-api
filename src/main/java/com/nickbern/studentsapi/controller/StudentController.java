package com.nickbern.studentsapi.controller;

import com.nickbern.studentsapi.dto.CreateStudentRequest;
import com.nickbern.studentsapi.dto.StudentResponse;
import com.nickbern.studentsapi.model.Student;
import com.nickbern.studentsapi.service.StudentService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/students")
public class StudentController {

    private final StudentService service;

    public StudentController(StudentService service) {
        this.service = service;
    }

    /** POST /students → 201 Created + header Location con la URL del nuevo recurso. */
    @PostMapping
    public ResponseEntity<StudentResponse> create(@Valid @RequestBody CreateStudentRequest request) {
        Student created = service.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(created.id())
                .toUri();
        return ResponseEntity.created(location).body(StudentResponse.from(created));
    }

    /** GET /students/{id} → 200 con el estudiante, o 404 si no existe. */
    @GetMapping("/{id}")
    public StudentResponse findById(@PathVariable UUID id) {
        return StudentResponse.from(service.findById(id));
    }

    /** GET /students → 200 con la lista (vacía si no hay registros). */
    @GetMapping
    public List<StudentResponse> findAll() {
        return service.findAll().stream()
                .map(StudentResponse::from)
                .toList();
    }
}
