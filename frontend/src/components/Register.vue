<template>
  <Toast position="bottom-center"></Toast>
  <div class="form-container">
    <div class="logo-container">
      <h1 class="app-name">Tasky</h1>
      <img src="/logo/Tasky.png" alt="Logo Tasky" class="app-logo" />
      <h2>Registro</h2>
    </div>
    <form @submit.prevent="register">
      <input v-model="form.name" type="text" placeholder="Nombre" required />
      <input v-model="form.email" type="email" placeholder="Email" required />
      <input v-model="form.password" type="password" placeholder="Contraseña" required />
      <input v-model="form.password_confirmation" type="password" placeholder="Confirmar contraseña" required />
      <button type="submit">Registrar</button>
      <a href="/login">¿Ya tienes cuenta? Inicia sesión</a>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import axios from '../api/axios';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { showSuccessToast, showErrorToast } from '../utils/toastUtils';

//Props del formulario 
const form = ref({
  name: '',
  email: '',
  password: '',
  password_confirmation: ''
});
const router = useRouter();
const toast = useToast();
//Función para registrar al usuario
const register = async () => {
  try {
    const res = await axios.post('/register', { user: form.value });
    showSuccessToast(toast, 'Registrado correctamente. Ahora puedes iniciar sesión.');

    form.value = {
      name: '',
      email: '',
      password: '',
      password_confirmation: ''
    };
    
    setTimeout(() => {
      router.push('/login');
    }, 3000);
  } catch (err) {
    showErrorToast(
      toast,
      err.response?.data?.errors?.join(', ') || 'Error al registrar.'
    );
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
