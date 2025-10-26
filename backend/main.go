package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type DesignInput struct {
	ImageURL    string `json:"imageURl" binding:"required,url"`
	Title       string `json:"title" binding:"required,max=120"`
	Description string `json:"description" binding:"required,max=2000"`
	Tags        string `json:"tags" binding:"max=200"`
}

type Design struct {
	ID          string    `json:"id"`
	CreatedAt   time.Time `json:"createdAt"`
	ImageURL    string    `json:"imageURL"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Tags        string    `json:"tags"`
}

var designs = make([]Design, 0)

func main() {
	r := gin.Default()
	// allow CORS for React dev server
	r.Use(cors.Default())

	r.Static("/uploads", "./uploads")

	r.POST("/api/LEGOdesigns", func(c *gin.Context) {
		file, err := c.FormFile("image")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Image file required",
			})
			return
		}

		// Saving the file to ./uploads folder
		filePath := fmt.Sprintf("./uploads/%s", file.Filename)
		if err := c.SaveUploadedFile(file, filePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
			return
		}

		title := c.PostForm("title")
		description := c.PostForm("description")
		tags := c.PostForm("tags")

		publicURL := fmt.Sprintf("http://localhost:8080/uploads/%s", file.Filename)

		newDesign := Design{
			ID:          uuid.NewString(),
			CreatedAt:   time.Now().UTC(),
			ImageURL:    publicURL,
			Title:       title,
			Description: description,
			Tags:        tags,
		}

		designs = append(designs, newDesign)
		c.JSON(http.StatusCreated, newDesign)
	})

	r.GET("/api/LEGOdesigns", func(c *gin.Context) {
		c.JSON(http.StatusOK, designs)
	})

	if err := r.Run(":8080"); err != nil {
		panic(err)
	}
}
