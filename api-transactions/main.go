package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

func main() {
	db, err := conectarDB()
	if err != nil {
		log.Fatal("No se pudo conectar a la base de datos:", err)
	}
	defer db.Close()

	var (
		lastDbCheck  time.Time
		lastDbStatus bool
		dbMu         sync.Mutex
	)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		responderJSON(w, http.StatusOK, map[string]string{"status": "ok", "servicio": "api-transacciones"})
	})
	mux.HandleFunc("GET /health/live", func(w http.ResponseWriter, r *http.Request) {
		responderJSON(w, http.StatusOK, map[string]string{"status": "UP"})
	})
	mux.HandleFunc("GET /health/ready", func(w http.ResponseWriter, r *http.Request) {
		dbMu.Lock()
		if time.Since(lastDbCheck) < 3*time.Second {
			statusOk := lastDbStatus
			dbMu.Unlock()
			if statusOk {
				responderJSON(w, http.StatusOK, map[string]string{"status": "UP"})
			} else {
				responderJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "DOWN"})
			}
			return
		}
		dbMu.Unlock()

		ctx, cancel := context.WithTimeout(r.Context(), 1*time.Second)
		defer cancel()

		pingErr := db.PingContext(ctx)
		dbMu.Lock()
		lastDbCheck = time.Now()
		if pingErr != nil {
			lastDbStatus = false
			dbMu.Unlock()
			log.Printf("[HealthCheck] Transactions DB ping failed: %v", pingErr)
			responderJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "DOWN"})
			return
		}
		lastDbStatus = true
		dbMu.Unlock()

		responderJSON(w, http.StatusOK, map[string]string{"status": "UP"})
	})
	registrarRutas(mux, db)

	port := getEnv("PORT", "8080")
	addr := fmt.Sprintf(":%s", port)
	log.Printf("API de transacciones escuchando en el puerto %s", port)
	log.Fatal(http.ListenAndServe(addr, mux))
}
