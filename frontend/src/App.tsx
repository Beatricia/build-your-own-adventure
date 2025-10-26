import React from 'react';
import './App.css';
import DesignForm from './components/LEGODesignForm';
import DesignList from './components/DesignList';

function App() {
  return (
    <div className='App'>
      <h1>LEGO Design</h1>
      <DesignForm />
      <hr />
      <DesignList />
    </div>
  );
}

export default App;