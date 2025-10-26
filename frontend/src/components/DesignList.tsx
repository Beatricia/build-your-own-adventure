import React, { useEffect, useState } from "react";
import { api } from "../api";
import { Design } from "../interfaces/Design";

export default function DesignList({designs}: {designs: Design[]}) {
  return (
        <div>
          <h2>Submitted Designs</h2>
          {designs.length === 0 ? (
            <p>No designs found.</p>
          ) : (
            <ul>
              {designs.map((d) => {
                return (
                <li key={d.id}>
                  <strong>Title: {d.title}</strong>
                  <br />
                  <small>Description: {d.description}</small>
                  <br />
                  <img src={d.imageURL} alt={d.title} width="200" />
                  <br />
                  <small>{d.tags}</small>
                </li>
                );
              })}
            </ul>
          )}
        </div>
      );
}