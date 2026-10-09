package ar.edu.utn.frc.devops.facturas;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;
import java.util.Map;

@RestController
public class HealthController {

    private final DataSource dataSource;
    private long lastDbCheck = 0;
    private boolean lastDbStatus = false;

    public HealthController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping("/")
    public Map<String, String> root() {
        return Map.of("status", "ok", "servicio", "api-facturas");
    }

    @GetMapping("/health/live")
    public Map<String, String> liveness() {
        return Map.of("status", "UP");
    }

    @GetMapping("/health/ready")
    public synchronized ResponseEntity<Map<String, String>> readiness() {
        long now = System.currentTimeMillis();
        if (now - lastDbCheck < 3000) {
            return lastDbStatus
                    ? ResponseEntity.ok(Map.of("status", "UP"))
                    : ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("status", "DOWN"));
        }

        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.setQueryTimeout(1);
            stmt.execute("SELECT 1");
            lastDbStatus = true;
            lastDbCheck = now;
            return ResponseEntity.ok(Map.of("status", "UP"));
        } catch (Exception e) {
            System.err.println("[HealthCheck] Invoices DB ping failed: " + e.getMessage());
            lastDbStatus = false;
            lastDbCheck = now;
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("status", "DOWN"));
        }
    }
}
