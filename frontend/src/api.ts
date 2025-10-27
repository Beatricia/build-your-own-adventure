import axios from "axios";

export const api = axios.create({
    baseURL: process.env.REACT_APP_API_BASE || "http://localhost:8080",
});

console.log("API baseURL:", api.defaults.baseURL);