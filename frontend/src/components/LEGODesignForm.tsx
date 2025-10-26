import React, { useState } from "react";
// api is an axios state that talks with GO
import { api } from "../api";
// no id, time of creation and img path
import { NewDesignPayload } from "../interfaces/Design";

export default function DesignForm( {onUploadSuccess}: {onUploadSuccess: () => void} ) {
  const [designData, setDesignData] = useState<NewDesignPayload>({
    title: "",
    description: "",
    tags: ""
  });
  const [file, setFile] = useState<File | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setDesignData(prev => ({ ...prev, [name]: value }));
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0]);
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
    formData.append("tags", designData.tags);

    try {
      await api.post("/api/LEGOdesigns", formData, {
        headers: { "Content-Type": "multipart/form-data" }
      });
      onUploadSuccess();
      setFile(null);
      setDesignData({ title: "", description: "", tags: "" });

    } catch (error) {
      console.error("Upload failed:", error);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="file" accept="image/*" onChange={handleFileChange} placeholder="Image URL" />
      <input name="title" value={designData.title} onChange={handleChange} placeholder="Title" />
      <input name="description" value={designData.description} onChange={handleChange} placeholder="Description" />
      <input name="tags" value={designData.tags} onChange={handleChange} placeholder="Tags" />
      <button type="submit">Submit</button>
    </form>
  );
}
