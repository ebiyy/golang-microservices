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
			"service": "user-service",
		})
	})

	r.GET("/users/:id", func(c *gin.Context) {
		userID := c.Param("id")
		// 実際の実装ではデータベースからユーザー情報を取得
		c.JSON(http.StatusOK, gin.H{
			"id":    userID,
			"name":  "サンプルユーザー",
			"email": "user@example.com",
		})
	})

	r.PUT("/users/:id", func(c *gin.Context) {
		userID := c.Param("id")
		// ユーザー情報更新ロジック
		c.JSON(http.StatusOK, gin.H{
			"message": "ユーザー情報が更新されました",
			"id":      userID,
		})
	})

	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
