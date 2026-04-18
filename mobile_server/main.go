package main

import (
	"calculator/server/db"
	"calculator/server/graph"
	"log"
	"net/http"
	"os"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/99designs/gqlgen/graphql/playground"
)

func main() {
	// DB ga ulan
	db.Connect()

	// GraphQL server
	srv := handler.New(graph.NewExecutableSchema(graph.Config{
		Resolvers: &graph.Resolver{DB: db.DB},
	}))

	// CORS uchun transport
	srv.AddTransport(transport.POST{})
	srv.AddTransport(transport.Options{})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// CORS middleware
	http.Handle("/query", corsMiddleware(srv))
	http.Handle("/", corsMiddleware(playground.Handler("Calculator GraphQL", "/query")))

	log.Printf("🚀 Server ishga tushdi: http://localhost:%s", port)
	log.Printf("📊 GraphQL Playground: http://localhost:%s/", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

// CORS — Flutter dan so'rovlar uchun
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}
