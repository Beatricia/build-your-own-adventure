import React, { useEffect, useState } from "react";
import { api } from "../api";
import { Design } from "../interfaces/Design";
import "./DesignList.css";

export default function DesignList({designs}: {designs: Design[]}) {
    return (
    <div className="design-list">
      <h2>Your unique designs</h2>
      {designs.length === 0 ? (
        <p>No designs found.</p>
      ) : (
        <ul>
          {designs.map((d) => (
            <li key={d.id} className="design-card">
              <h3 className="design-title">{d.title}</h3>
              <div className="design-image">
                <img src={d.imageURL} alt={d.title} />
              </div>
              <p className="design-description">
                <strong>Description:</strong> {d.description}
              </p>
              <div className="design-tags">
                {d.tags
                  .split(",")
                  .map((tag, idx) => (
                    <span key={idx} className="tag">
                      {tag.trim()}
                    </span>
                  ))}
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}