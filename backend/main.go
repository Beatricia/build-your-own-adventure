package main

import (
	// format (Println)
	"fmt"
	// http client/server implementations (ex: http.StatusOK)
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	// GIN - web framework for Go - easier to build APIs, web servers and backend apps (no manyal low level HTTP handling)
	"github.com/gin-gonic/gin"
	// for generating UUIDs (Universally Unique identifiers)
	"github.com/google/uuid"
)

type Design struct {
	ID          string    `json:"id"`
	CreatedAt   time.Time `json:"createdAt"`
	ImageURL    string    `json:"imageURL"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Tags        string    `json:"tags"`
}

// in memory db -> should be switched to a database
var designs = make([]Design, 0)

func main() {
	r := gin.Default()
	// allow CORS for React dev server
	r.Use(cors.Default())

	// when someone looks for ..localhost:8080/uploads/... -> give them the backend/uploads folder
	r.Static("/uploads", "./uploads")

	// without GIN this would be more complicated to do
	// it talks with the backend using JSON
	r.POST("/api/LEGOdesigns", func(c *gin.Context) {
		// reading the file from the Form data the client (front) sent
		file, err := c.FormFile("image")
		// nill -> nothing, no value (null, None)
		// error is not nothing, so something went wrong
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

		// Getting the other fields from the form
		title := c.PostForm("title")
		description := c.PostForm("description")
		tags := c.PostForm("tags")

		// at startup (ensure uploads dir exists)
		_ = os.MkdirAll("./uploads", 0755)

		base := strings.TrimRight(os.Getenv("BACKEND_BASE_URL"), "/")
		// fallback for local dev
		if base == "" {
			base = "http://localhost:8080"
		}
		publicURL := fmt.Sprintf("%s/uploads/%s", base, file.Filename)

		// creating the data model object
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
