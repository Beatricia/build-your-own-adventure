# build-your-own-adventure
1. Create a repo and think of a structure 
  /frontend (Reac and TypeScript)
  /backend (Go or ?)
  /ops/terraform (if time left)
2. Frontend:
  Form for uploading the LEGO set design:
  - Title
  - Image?
  - Description
  - Tags (Castle, Space, City, etc.. )
  - Submit design
  - Create a list of designs with a preview img, title, description and tags. (When a new design is created, this list should be refreshed in real-time)
3. Backend:
  - Research what is Go service
  - data is stored locally
  - POST design(image, title, description, tags)
  - GET design
4. Connect the frontend to the backend
  - when post is reached -> refresh the list in real time
  - think how to update the list visually in real time?
5. Infrastructure
  - Front S3 bucket
  - Back EC2 instance running on the Go API
6. Pipeline?
