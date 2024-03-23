package com.example.restservice;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

	private static final String template = "Hello, %s!";
	private final AtomicLong counter = new AtomicLong();

	@GetMapping("/hello")
	public String greeting(@RequestParam(value = "name", defaultValue = "World") String name) {
		return "hello";
	}

	@GetMapping("/current-date")
    public String getCurrentDate() {
        String jdbcUrl = "jdbc:mysql://"+ System.getenv("DB_HOST") +"/"+ System.getenv("DB_NAME") +"?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
        String username = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");
        String sql = "SELECT NOW() AS mydate";

		System.out.println("**** JDBC URL "  + jdbcUrl);

        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password);
             PreparedStatement preparedStatement = connection.prepareStatement(sql);
             ResultSet resultSet = preparedStatement.executeQuery()) {

            if (resultSet.next()) {
                String currentDate = resultSet.getString("mydate");
                return "Current Date: " + currentDate;
            } else {
                return "Date not found";
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return "Error fetching date";
        }
    }

}