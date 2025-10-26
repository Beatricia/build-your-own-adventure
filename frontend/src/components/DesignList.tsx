import React, { useEffect, useState } from "react";
import { api } from "../api";

interface Design {
  id: string;
  imageURl: string;
  title: string;
  description: string;
  tags: string;
  createdAt: string;
}

export default function DesignList() {
    const [designs, setDesigns] = useState<Design[]>([]);

    useEffect(() => {
        const fetchData = async () => {
            const response = await api.get("/api/LEGOdesigns");
            setDesigns(response.data);
        };
        fetchData();
    }, []);

return (
    <div>
      <h2>Submitted Designs</h2>
      {designs.length === 0 ? (
        <p>No designs found.</p>
      ) : (
        <ul>
          {designs.map((d) => (
            <li key={d.id}>
              <strong>{d.title}</strong> — {d.description}
              <br />
              <a href={d.imageURl} target="_blank" rel="noreferrer">
                {d.imageURl}
              </a>
              <br />
              <small>{d.tags}</small>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}