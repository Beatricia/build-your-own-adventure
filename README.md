# build-your-own-adventure
1. Create a repo and think of a structure  (All done)
- frontend (Reac and TypeScript)
  - backend (Go ?)
  - infrastructure (Terrform)
2. Frontend - Form for uploading the LEGO set design (All done):
  - Title
  - Image?
  - Description
  - Tags (Castle, Space, City, etc.. )
  - Submit design
  - Create a list of designs with a preview img, title, description and tags. (When a new design is created, this list should be refreshed in real-time)
3. Backend  (All done)
  - Research what is Go service
  - data is stored locally
  - POST design(image, title, description, tags)
  - GET design
4. Connect the frontend to the backend  (All done)
  - when post is reached -> refresh the list in real time
  - think how to update the list visually in real time?
5. Infrastructure (Didn t succed)
  - Front CloudFront S3
  - Back Docker conainter deployed on an EC2
6. Pipeline? (Didn t succed)


## Actions & Commands

| **Action**                            | **Command**                                                                                     |
|-------------------------------------------|-----------------------------------------------------------------------------------------------------|
| Recreate everything                       | `terraform init`<br>`terraform apply`                                                                |
| See URLs again                            | `terraform output`                                                                                  |
| Redeploy React frontend                   | `cd frontend`<br>`REACT_APP_API_BASE="http://<EC2_PUBLIC_IP>:8080" npm run build`<br>`aws s3 sync build/ s3://build-your-own-adventure-frontend-bucket --delete` |
| Destroy infrastructure                    | `terraform destroy`                                                                                 |
| Redeploy Go backend                       | `terraform apply`                                                                                   |
| Backend                                   | cd backend + go run .                                                                               |
| Frontend                                  | cd frontend + npm start                                                                             |

---

