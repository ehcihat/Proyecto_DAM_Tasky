<template>
  <!-- Header global -->
  <Header />
  <Toast position="bottom-center" />
  <div class="header-offset"></div>

  <div class="projects-container">
    <h1 class="projects-title">Proyectos</h1>
    <div v-if="projects.length > 0" class="project-cards">
      <div
        v-for="project in projects"
        :key="project._id"
        class="project-card"
        @click="goToLists(project._id)"
      >
        <div class="card-header">
          <strong class="card-title">{{ project.title }}</strong>
          <i
            class="pi pi-ellipsis-v card-menu"
            @click.stop="toggleMenu(project._id)"
            style="cursor: pointer;"
          ></i>
        </div>

        <small>{{ project.description }}</small>

        <!--Menú desplegable para editar-->
        <div v-if="selectedProjectId === project._id" class="card-actions">
          <button class="edit-btn" @click.stop="startEditing(project)">
            <i class="pi pi-pencil"></i> Editar
          </button>
          <button class="delete-btn" @click.stop="confirmDelete(project._id)">
            <i class="pi pi-trash"></i> Borrar
          </button>
        </div>
      </div>
    </div>
    <p v-else>No tienes proyectos todavía.</p>

    <button class="create-project-btn" @click="openModal">Crear Proyecto</button>

    <!--Modal de creación del proyecto -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <h2>Crear Proyecto</h2>
        <form @submit.prevent="createProject">
          <input
            v-model="newProject.title"
            placeholder="Título del proyecto"
            required
          />
          <textarea
            v-model="newProject.description"
            placeholder="Descripción del proyecto"
            rows="3"
          ></textarea>
          <div class="modal-buttons">
            <button type="submit">Crear</button>
            <button type="button" @click="closeModal">Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <!--Modal de edición del proyecto -->
  <div v-if="editingProjectId" class="modal-overlay" @click.self="cancelEditing">
    <div class="modal">
      <h2>Editar Proyecto</h2>
      <form @submit.prevent="updateProject(editingProjectId)">
        <input
          v-model="editedProject.title"
          placeholder="Título del proyecto"
          required
        />
        <textarea
          v-model="editedProject.description"
          placeholder="Descripción del proyecto"
          rows="3"
        ></textarea>
        <div class="modal-buttons">
          <button type="submit">Guardar</button>
          <button type="button" @click="cancelEditing">Cancelar</button>
        </div>
      </form>
    </div>
  </div>



</template>


<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { useRouter } from 'vue-router'
import Header from './Header.vue'
import { useToast } from 'primevue/usetoast'
import { showSuccessToast, showErrorToast } from '../utils/toastUtils'

const toast = useToast()
const router = useRouter()
const projects = ref([])
const newProject = ref({ title: '', description: '' })
const token = localStorage.getItem('token')
const editingProjectId = ref(null)
const editedProject = ref({ title: '', description: ''})
const BASE_URL = 'http://localhost:3000'
const showModal = ref(false)
const selectedProjectId = ref(null)

//Llamada al backend para obtener la lista de proyectos
const fetchProjects = async () => {
  try {
    const response = await axios.get(`${BASE_URL}/projects`, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })
    projects.value = response.data
  } catch (error) {
    console.error('Error al cargar proyectos:', error)
    showErrorToast(toast, 'No se pudieron cargar los proyectos')
  }
}
//Función que llama al endpoint de POST para crear un proyecto
const createProject = async () => {
  try {
    const response = await axios.post(`${BASE_URL}/projects`, {
      project: newProject.value
    }, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })
    
    projects.value.push(response.data)
    newProject.value = { title: '', description: '' }
    showSuccessToast(toast, 'Proyecto creado exitosamente.')
    

    closeModal()
  } catch (error) {
    console.error('Error al crear proyecto:', error)
    showErrorToast(toast,'Error al crear el proyecto')
  }
}
//Función que carga los datos actuales del proyecto
const startEditing = (project) => {
  editingProjectId.value = project._id
  editedProject.value = {title: project.title, description: project.description}
}
//Función para cancelar la edición limpiando los campos
const cancelEditing = () => {
  editingProjectId.value = null
  editedProject.value = {title: '', description: ''}
}
//Función que llama al endpoint PUT para actualizar los proyectos
const updateProject = async (projectId) => {
  try {

    await axios.put(`${BASE_URL}/projects/${projectId}`, {
      project: editedProject.value
    }, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })

    const index = projects.value.findIndex(p => p._id === projectId)
    if (index !== -1){
      projects.value[index].title = editedProject.value.title
      projects.value[index].description = editedProject.value.description
    }
    showSuccessToast(toast, 'Proyecto actualizado')
    cancelEditing()

  } catch (error) {
    console.error('Error al actualizar proyecto: ', error)
    showErrorToast(toast,'Error al actualizar el proyecto')

  }
}
//Abrir y cerrar el modal
const openModal = () => {
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

//Confirmamos para borrar el proyecto y mostramos qué contiene
const confirmDelete= async (projectId) => {
  try {
    const listResponse = await axios.get(`${BASE_URL}/projects/${projectId}`, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })

    const project = listResponse.data
    const numLists = project.lists.length
    const totalTasks = project.lists.reduce((sum, list) => sum + (list.tasks?.length || 0), 0)

    const confirmMsg = `¿Estás seguro que quieres eliminar el proyecto "${project.title}"?\n
    Tiene ${numLists} lista(s) con ${totalTasks} tarea(s).`

    if (confirm(confirmMsg)){
      await deleteProject(projectId)
    }

  } catch (error) {
    console.error('Error al obtener el proyecto: ',error)
    showErrorToast(toast, 'Error al intentar verficar las listas y tareas.')
  }
}
//Realiza el borrado del proyecto
const deleteProject = async (projectId) => {
  try {
    await axios.delete(`${BASE_URL}/projects/${projectId}`, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })

    projects.value = projects.value.filter(p => p._id !== projectId)
   showSuccessToast(toast,'Proyecto eliminado exitosamente.')

  } catch (error) {
    console.error('Error al eliminar el proyecto: ', error)
    showErrorToast(toast,'Error al eliminar el proyecto.')

  }
}

//Router hacia las listas
const goToLists = (projectId) => {
  router.push(`/projects/${projectId}/lists`)
}
//Para hacer aparecer o desaparecer el proyecto
const toggleMenu = (projectId) => {
  selectedProjectId.value = selectedProjectId.value === projectId ? null : projectId
}


onMounted(fetchProjects)
</script>
<style scoped>

.projects-container {
  position: relative;
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
  border-radius: 10px;
  background-color: #f8f9fa;
  color: #333;
}

.projects-title {
  position: absolute;
  top: 20px;
  right: 20px;
  margin: 0;
  font-size: 1.5rem;
  color: #333;
}

.create-project-btn {
  position: fixed;
  bottom: 40px;
  right: 40px;
  padding: 1rem 2rem; 
  font-size: 1.25rem; 
  background-color: #61c081;
  color: #fff;
  border: none;
  border-radius: 50px;
  cursor: pointer;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
  transition: background-color 0.2s ease;
  z-index: 1000;
}
.create-project-btn:hover {
  background-color: #4ca966;
}

.project-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-top: 80px;
  margin-bottom: 80px;
}

.project-card {
  border: 1px solid #ccc;
  padding: 1rem;
  text-align: center;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  cursor: pointer;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  background-color: #fff;
  color: #333;
  animation: fadeInUp 0.5s ease forwards;
}
.project-card:hover {
  transform: translateY(-4px);
}

.card-actions {
  display: flex;
  justify-content: space-around;
  margin-top: 0.5rem;
}

.edit-btn,
.delete-btn {
  padding: 0.3rem 0.6rem;
  font-size: 0.9rem;
  border: none;
  background: transparent;
  cursor: pointer;
}
.edit-btn {
  color: #007bff;
}
.delete-btn {
  color: #dc3545;
}
.edit-btn:hover {
  text-decoration: underline;
}
.delete-btn:hover {
  text-decoration: underline;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  margin-bottom: 0.5rem;
}
.card-title {
  font-weight: bold;
  font-size: 1.1rem;
  text-align: center;
  margin: 0 auto;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  width: 100%;
}
.card-actions {
  margin-top: 0.5rem;
  display: flex;
  gap: 0.5rem;
}

.pi {
  font-size: 1.2rem;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1100;
}


.modal {
  background: #fff;
  color: #333;
  padding: 2rem;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.modal input,
.modal textarea {
  width: 100%;
  padding: 0.5rem;
  margin-top: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 1rem;
  color: #333;
  background-color: #fff;
}
.modal input:focus,
.modal textarea:focus {
  border-color: #61c081;
  outline: none;
}

.modal-buttons {
  margin-top: 1rem;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
.modal-buttons button {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s ease;
}
.modal-buttons button[type="submit"] {
  background-color: #61c081;
  color: #fff;
}
.modal-buttons button[type="button"] {
  background-color: #ccc;
  color: #333;
}
.modal-buttons button:hover {
  opacity: 0.9;
}


.header-offset {
  height: 80px;
  flex-shrink: 0;
}

</style>
