export interface Design {
  id: string;
  imageURL: string;
  title: string;
  description: string;
  tags: string;
  createdAt: string;
}

export interface NewDesignPayload {
  title: string;
  description: string;
  tags: string;
}