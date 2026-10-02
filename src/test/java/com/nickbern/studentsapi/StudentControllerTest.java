package com.nickbern.studentsapi;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_EACH_TEST_METHOD)
class StudentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private static final String VALID_BODY = """
            {"nombre": "Ana", "apellido": "Gómez", "correo": "ana.gomez@unisalle.edu.co"}
            """;

    @Test
    void createReturns201WithLocationAndId() throws Exception {
        mockMvc.perform(post("/students").contentType(MediaType.APPLICATION_JSON).content(VALID_BODY))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"))
                .andExpect(jsonPath("$.id", notNullValue()))
                .andExpect(jsonPath("$.nombre").value("Ana"))
                .andExpect(jsonPath("$.correo").value("ana.gomez@unisalle.edu.co"));
    }

    @Test
    void createdStudentCanBeFetchedByIdAndListed() throws Exception {
        String location = mockMvc.perform(post("/students")
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_BODY))
                .andReturn().getResponse().getHeader("Location");

        mockMvc.perform(get(location))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.apellido").value("Gómez"));

        mockMvc.perform(get("/students"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }

    @Test
    void invalidBodyReturns400WithFieldErrors() throws Exception {
        String body = """
                {"nombre": "", "apellido": "Gómez", "correo": "no-es-correo"}
                """;
        mockMvc.perform(post("/students").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errores.nombre", notNullValue()))
                .andExpect(jsonPath("$.errores.correo", notNullValue()));
    }

    @Test
    void duplicateEmailReturns409() throws Exception {
        mockMvc.perform(post("/students").contentType(MediaType.APPLICATION_JSON).content(VALID_BODY))
                .andExpect(status().isCreated());
        mockMvc.perform(post("/students").contentType(MediaType.APPLICATION_JSON).content(VALID_BODY))
                .andExpect(status().isConflict());
    }

    @Test
    void unknownIdReturns404() throws Exception {
        mockMvc.perform(get("/students/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    void malformedIdReturns400() throws Exception {
        mockMvc.perform(get("/students/abc"))
                .andExpect(status().isBadRequest());
    }
}
