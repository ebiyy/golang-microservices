package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "payment-service",
		})
	})

	r.POST("/payments", func(c *gin.Context) {
		// 決済処理ロジック
		c.JSON(http.StatusCreated, gin.H{
			"payment_id": "pay123",
			"status":     "completed",
			"amount":     5000,
		})
	})

	r.GET("/payments/:id", func(c *gin.Context) {
		paymentID := c.Param("id")
		// 決済情報取得ロジック
		c.JSON(http.StatusOK, gin.H{
			"payment_id": paymentID,
			"status":     "completed",
			"amount":     5000,
			"created_at": "2023-06-01T12:00:00Z",
		})
	})

	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
