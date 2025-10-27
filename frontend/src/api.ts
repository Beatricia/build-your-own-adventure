// src/api.ts
import axios from "axios";

// use the current origin (https://<your-cloudfront-domain>)
export const api = axios.create({
  baseURL: window.location.origin,
});