// Importa las funciones que necesitas desde Firebase SDK
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

// Configuración de Firebase de tu proyecto
const firebaseConfig = {
  apiKey: "AlzaSyAz9ZfJp2d1uUQ0CcApVRvj8K_j_co7Tc",
  authDomain: "chattdp-b2ab5.firebaseapp.com",
  projectId: "chattdp-b2ab5",
  storageBucket: "chattdp-b2ab5.appspot.com",
  messagingSenderId: "746779309482",
  appId: "1:746779309482:web:d901d07f4125622e6827d3",
};

// Inicializa Firebase
const app = initializeApp(firebaseConfig);

// Inicializa Firebase Authentication y obtiene una referencia al servicio
const auth = getAuth(app);
