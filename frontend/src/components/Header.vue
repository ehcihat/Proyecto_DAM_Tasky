<template>
  <header class="app-header">
    <!--Div que creamos para poner nombre de la aplicación y logo -->
    <div class="app-name">
      <h1>Tasky</h1>
      <img src="/logo/Tasky.png" alt="Logo Tasky" class="app-logo" />
    </div>

    <!--Div para la parte de perfil del usuario -->
    <div class="profile">
      <span class="username" @click="toggleDropdown">
        {{ userName || 'Invitado' }} 
        <i class="dropdown-icon">▼</i>
      </span>
<!--Dropdown-->
      <div v-if="dropdownVisible" class="dropdown-menu">
        <a href="/projects" class="dropdown-item">Mis Proyectos</a>
        <button @click="logout" class="dropdown-item logout-button">Cerrar sesión</button>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';

const router = useRouter();
const dropdownVisible = ref(false);
const userName = ref('');  

const token = localStorage.getItem('token');
//Obtenemos con un método GET el usuario actual
const fetchCurrentUser = async () => {
  if (!token) {

    router.push('/login');
    return;
  }

  try {
    const response = await axios.get('http://localhost:3000/current_user', {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    userName.value = response.data.name; 
  } catch (error) {
    console.error('Error al obtener usuario:', error);
    userName.value = 'Invitado'; 
  }
};

onMounted(fetchCurrentUser);

const toggleDropdown = () => {
  dropdownVisible.value = !dropdownVisible.value;
};

const logout = () => {
  const confirmMsg = `¿Estás seguro que quieres cerrar sesión?`
  if (confirm(confirmMsg)) {
    localStorage.removeItem('token');
    localStorage.removeItem('user'); 
    router.push('/login');
  }



  
};
</script>

<style scoped>
.app-header {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  background: linear-gradient(to right, #3ea2ca, #3da726);
  padding: 1rem 2rem;
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-sizing: border-box;
  border-radius: 10px;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  font-family: 'Inter', sans-serif;
}

.app-name h1 {
  font-size: 1.5rem;
  margin: 0;
}

.profile {
  position: relative;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center; 
}

.username {
  display: inline-flex;
  align-items: center;
  font-size: 1rem;
  padding: 0.5rem;
}

.dropdown-icon {
  margin-left: 5px;
}

.dropdown-menu {
  position: absolute;
  top: calc(100% + 0.5rem);
  left: 50%;
  transform: translateX(-50%);
  background-color: #fff;
  color: #333;
  border: 1px solid #ddd;
  border-radius: 5px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  padding: 0.5rem 0;
  z-index: 1001;
  min-width: 150px;
  max-width: 90vw;
}

.dropdown-item {
  display: block;
  padding: 0.75rem 1rem;
  text-decoration: none;
  color: #333;
  transition: background-color 0.2s ease;
}


.dropdown-item:hover {
  background-color: #f1f1f1;
}


.logout-button {
  background-color: rgb(233, 6, 6);
  color: white;
  border: none;
  padding: 0.75rem 1rem;
  text-align: center;
  cursor: pointer;
  border-radius: 5px;
  width: 100%;
  transition: background-color 0.2s ease;
}

.logout-button:hover {
  background-color:rgb(202, 16, 16);
}


@media (max-width: 480px) {
  .dropdown-menu {
    left: 50%;
    transform: translateX(-50%);
    width: 90vw;
  }
  .dropdown-item, .logout-button {
    padding: 0.65rem 0.75rem;
    font-size: 0.9rem;
  }
}
.app-logo{
  width: 15%;

}
</style>
