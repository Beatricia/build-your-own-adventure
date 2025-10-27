import './App.css';
import DesignForm from './components/LEGODesignForm';
import DesignList from './components/DesignList';
import React, { useEffect, useState } from "react";
import { api } from "./api";
import { Design } from "./interfaces/Design";


function App() {
  // the list of all the designs that are updated once the onUploadSuccess is successfull
  // everytime the designs state changes, it is passed to the list, and react rerenders the app
  const [designs, setDesigns] = useState<Design[]>([]);

  // fetching the designs from the backend
  const fetchDesigns = async () => {
    const response = await api.get("/api/LEGOdesigns");
    setDesigns(response.data);
  }

  // this is called first 
  useEffect(() => {
    fetchDesigns();
  }, []);
  
  return (
    <div className='App'>
      <h2>Build Your Own Adventure</h2>
      <DesignForm onUploadSuccess={fetchDesigns} />

      <DesignList designs={designs} />
    </div>
  );
}

export default App;