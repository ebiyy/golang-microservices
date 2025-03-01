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
			"service": "auth-service",
		})
	})

	r.POST("/auth/login", func(c *gin.Context) {
		// 認証ロジック（実際の実装ではデータベース検証などが必要）
		c.JSON(http.StatusOK, gin.H{
			"token":   "sample-token",
			"user_id": "user123",
		})
	})

	r.POST("/auth/register", func(c *gin.Context) {
		// ユーザー登録ロジック
		c.JSON(http.StatusCreated, gin.H{
			"message": "ユーザーが登録されました",
			"user_id": "user123",
		})
	})

	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
