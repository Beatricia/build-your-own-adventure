import React, { useState } from "react";
// api is an axios state that talks with GO
import { api } from "../api";
// no id, time of creation and img path
import { NewDesignPayload } from "../interfaces/Design";
import "./LEGODesignForm.css";

export default function DesignForm( {onUploadSuccess}: {onUploadSuccess: () => void} ) {
  const [designData, setDesignData] = useState<NewDesignPayload>({
    title: "",
    description: "",
    tags: ""
  });
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setDesignData(prev => ({ ...prev, [name]: value }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  const selectedFile = e.target.files?.[0];
  if (selectedFile) {
    setFile(selectedFile);
    setPreview(URL.createObjectURL(selectedFile));
  }
};

  // submitting the form
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    // preventing the browser to refresh the page on form submit
    e.preventDefault();
    // we need FormData for the file uploads
    const formData = new FormData();
    if(file) formData.append('image', file);
    formData.append("title", designData.title);
    formData.append("description", designData.description);
    const formattedTags = designData.tags
      .split(" ")
      .filter(tag => tag.trim() !== "")
      .map(tag => `#${tag}`)
      .join(" ");

    formData.append("tags", formattedTags);

    try {
      await api.post("/api/LEGOdesigns", formData, {
        headers: { "Content-Type": "multipart/form-data" }
      });
      onUploadSuccess();
      setFile(null);
      setPreview(null);
      setDesignData({ title: "", description: "", tags: "" });

    } catch (error) {
      console.error("Upload failed:", error);
    }
  };

  return (
    <form className="design-form" onSubmit={handleSubmit}>
      {/* LEFT: image preview + file input */}
      <div className="left-section">
        <div className="image-preview">
          {preview ? <img src={preview} alt="preview" /> : <span>No image selected</span>}
        </div>
        <input type="file" accept="image/*" onChange={handleFileChange} />
      </div>

      {/* RIGHT: text fields + button */}
      <div className="form-fields">
        <div className="field-row">
          <label>Title</label>
          <input
            name="title"
            value={designData.title}
            onChange={handleChange}
            placeholder="Title"
          />
        </div>

        <div className="field-row">
          <label>Description</label>
          <input
            name="description"
            value={designData.description}
            onChange={handleChange}
            placeholder="Description"
          />
        </div>

        <div className="field-row">
          <label>Tags</label>
          <input
            name="tags"
            value={designData.tags}
            onChange={handleChange}
            placeholder="Tags"
          />
        </div>

        <button className="lego-btn" type="submit">Submit</button>
      </div>
    </form>
  );
}
