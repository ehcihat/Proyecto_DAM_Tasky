<template>
  <Toast position="bottom-center"></Toast>
  <div class="form-container">
    <div class="logo-container">
      <h1 class="app-name">Tasky</h1>
      <img src="/logo/Tasky.png" alt="Logo Tasky" class="app-logo" />
      <h2>Iniciar sesión</h2>
    </div>
    <form @submit.prevent="login">
      <input v-model="form.email" type="email" placeholder="Email" required />
      <input v-model="form.password" type="password" placeholder="Contraseña" required />
      <button type="submit">Iniciar sesión</button>
      <a href="/register">¿No tienes cuenta todavía? Regístrate</a>
    </form>
  </div>
  
</template>

<script setup>
import { ref } from 'vue';
import axios from '../api/axios';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { showSuccessToast, showErrorToast } from '../utils/toastUtils';

const form = ref({
  email: '',
  password: ''
});
const router = useRouter();
const toast = useToast();
//Realizamos el login confirmando el usuario y haciendo POST del token.
const login = async () => {
  try {
    const res = await axios.post('/login', form.value);
    localStorage.setItem('token', res.data.token);
    
    showSuccessToast(toast, 'Inicio de sesión exitoso. Redirigiendo a Proyectos...');
    setTimeout(() => {
      router.push('/projects');
     
    }, 3000);
  } catch (err) {

    showErrorToast(toast, 'Credenciales incorrectas.');
  }
};
</script>

<style scoped>
.form-container {
  width: 90%;
  max-width: 400px;
  margin: 5vh auto;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background: #f9fafb;
  padding: 2rem;
  border-radius: 10px;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
}


h2 {
  color: #333;
  margin-bottom: 1rem;
  font-family: 'Arial', sans-serif;
  font-weight: 600;
}

.logo-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 2rem;
}

.app-name {
  font-size: 1.8rem;
  color: #333;
  margin-bottom: 0.5rem;
}


.app-logo {
  width: 100px;
  opacity: 0.3;
  display: block;
}


input {
  width: 100%;
  padding: 0.75rem;
  margin-bottom: 1rem;
  border: 1px solid #ccc;
  border-radius: 5px;
  font-size: 1rem;
  background-color: #fff;
  color: #333;
  box-sizing: border-box;
  transition: border 0.3s ease;
}

button {
  width: 100%;
  padding: 0.75rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.3s ease;
}

button:hover {
  background-color: #0056b3;
}


a {
  margin-top: 1rem;
  font-size: 0.9rem;
  color: #007bff;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

@media (max-width: 480px) {
  .form-container {
    padding: 1.5rem;
    margin: 10vh auto;
  }
  
  input, button {
    font-size: 0.95rem;
  }
}
</style>
