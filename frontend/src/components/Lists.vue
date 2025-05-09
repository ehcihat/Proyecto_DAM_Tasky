<template>
  <Header />
  <Toast position="bottom-center" />
  <button class="back-btn" @click="goBack"><i class="pi pi-directions-alt"></i>Volver</button>
  <div class="header-offset"></div>
  <div class="project-lists">

    <h1>{{ project.title }}</h1>
    <p>{{ project.description }}</p>
    
    <div v-if="project.lists.length > 0" class="lists-container">
      <div 
        v-for="list in project.lists" 
        :key="list._id" 
        class="list-column"
        :data-list-id="list._id"
      >

        <div v-if="editingListId === list._id" class="edit-mode">
          <input 
            v-model="editedListTitle" 
            class="edit-input"
            placeholder="Editar título"
          />
          <button @click="updateList(list._id)" class="save-btn">
            <i class="pi pi-check"></i>
          </button>
          <button @click="cancelEditList" class="cancel-btn">
            <i class="pi pi-times"></i>
          </button>
        </div>

        <div v-else>
          <div class="list-header">
            <strong class="list-title">{{ list.title }}</strong>
            <div class="dropdown">
              <i 
                class="pi pi-ellipsis-v list-menu" 
                @click.stop="toggleListMenu(list._id)"
                style="cursor: pointer;"
              ></i>
              <div v-if="selectedListId === list._id" class="dropdown-menu">
                <button class="edit-btn" @click.stop="startEditList(list)">
                  <i class="pi pi-pencil"></i> Editar
                </button>
                <button class="delete-btn" @click.stop="confirmDeleteList(list._id)">
                  <i class="pi pi-trash"></i> Borrar
                </button>
              </div>
            </div>
          </div>
        </div>

        <!--Draggable para poder desplazar las tareas -->
        <draggable 
          v-model="list.tasks" 
          group="tasks" 
          item-key="_id" 
          :disabled="isEditingTask"
          @end="onDrop"
        >
          <template #item="{ element }">
            <div :data-task-id="element._id">
              <Tasks 
                :task="element" 
                :completed="element.completed"
                :list-id="list._id" 
                @editTask="editTask" 
                @deleteTask="deleteTask" 
                @setEditing="setEditingTask" 
              />
            </div>
          </template>
        </draggable>
        <button class="new-task-btn" @click="openNewTaskModal(list._id)">+ Añadir tarea</button>
      </div>
    </div>
    <div v-else>
      <p>Este proyecto aún no tiene listas. ¡Añade algunas listas para comenzar!</p>
    </div>
    <!--Formulario para crear nueva lista -->
    <div class="new-task-form" v-if="isCreatingList">
      <input type="text" v-model.trim="newListTitle" placeholder="Título de la lista" />
      <button @click="createList">Crear lista</button>
      <button @click="isCreatingList = false">Cancelar</button>
    </div>
    <button v-else @click="isCreatingList = true">+ Añadir lista</button>
  </div>

  <!--Modal para crear nueva tarea-->
  <Dialog 
    v-model:visible="showNewTaskModal" 
    style="background-color: #fff;"
    modal 
    :closable="false"
    contentClass="dialog-content"
  >  
    <template #header>
      <h3 class="dialog-header">Crear Tarea</h3>
    </template>
    <div class="new-task-modal-content">
      <div class="col title-des">
        <div class="field">
          <label for="new-task-title" style="color: black;">Título</label>
          <input 
            id="new-task-title"
            v-model.trim="newTask.title" 
            type="text" 
            class="edit-input" 
            placeholder="Título de la tarea" 
            required
          />
        </div>
        <div class="field">
          <label for="new-task-description" style="color: black;">Descripción</label>
          <textarea 
            id="new-task-description" 
            v-model.trim="newTask.description" 
            rows="4" 
            class="edit-input" 
            placeholder="Descripción de la tarea"
          ></textarea>
        </div>
      </div>
      <!--Calendario y comentarios-->
      <div class="col cal-coment">
        <div class="field">
          <label for="new-task-due-date" style="color: black;">Fecha y hora de vencimiento</label>
          <DatePicker 
            id="new-task-due-date"
            v-model="newTask.due_date"
            :showTime="true" 
            hourFormat="24" 
            format="dd/MM/yy HH:mm"
            class="edit-input"
          />
        </div>
        <div class="field">
          <label for="new-task-comments" style="color: black;">Comentarios</label>
          <textarea 
            id="new-task-comments"
            v-model.trim="newTask.comments"
            rows="4" 
            class="edit-input" 
            placeholder="Comentarios"
          ></textarea>
        </div>
      </div>
    </div>
    <div class="modal-buttons">
      <button class="save-btn" @click="createTask">
        <i class="pi pi-check"></i> Crear Tarea
      </button>
      <button class="cancel-btn" @click="closeNewTaskModal">
        <i class="pi pi-times"></i> Cancelar
      </button>
    </div>
  </Dialog>
</template>


<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { useRoute } from 'vue-router'
import Header from './Header.vue'
import Tasks from './Tasks.vue'
import draggable from 'vuedraggable'
import Dialog from 'primevue/dialog'
import DatePicker from 'primevue/datepicker'
import { useToast } from 'primevue/usetoast'
import { showSuccessToast, showErrorToast } from '../utils/toastUtils'
import { useRouter } from 'vue-router'

//Props y variables de enrutamiento, estado del proyecto y token
const router = useRouter()
const toast = useToast()
const route = useRoute()
const projectId = route.params.projectId
const project = ref({ title: '', description: '', lists: [] })
const token = localStorage.getItem('token')
const BASE_URL = 'http://localhost:3000'

//Props para la edición de listas y tareas
const newListTitle = ref('')
const isCreatingList = ref(false)
const selectedListId = ref(null)
const editingListId = ref(null)
const editedListTitle = ref('')
const isEditingTask = ref(false)

const setEditingTask = editing => { isEditingTask.value = editing }

const goBack = () => {
  router.back()
}
//Petición get para obtener las listas
const fetchProjectLists = async () => {
  try {
    const response = await axios.get(`${BASE_URL}/projects/${projectId}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    project.value = response.data
    if (!Array.isArray(project.value.lists)) {
      project.value.lists = []
    }
  } catch (error) {
    console.error('Error al obtener el proyecto:', error)
  }
}

onMounted(fetchProjectLists)

const showNewTaskModal = ref(false)
const currentListId = ref(null)
const newTask = ref({
  title: '',
  description: '',
  due_date: null, 
  comments: ''
})
//Abrimos el modal de tarea nueva
const openNewTaskModal = (listId) => {
  currentListId.value = listId
  newTask.value = { title: '', description: '', due_date: null, comments: '' }
  showNewTaskModal.value = true
}
//Lo cerramos
const closeNewTaskModal = () => {
  showNewTaskModal.value = false
}
//Petición al endpoint para crear la tarea con el método POST
const createTask = async () => {
  if (!newTask.value.title.trim()) {
    alert('El título de la tarea es obligatorio')
    return
  }
  try {
    const taskData = {
      title: newTask.value.title.trim(),
      description: newTask.value.description.trim(),
      due_date: newTask.value.due_date ? newTask.value.due_date.toISOString() : null,
      comments: newTask.value.comments 
        ? newTask.value.comments.split(',').map(s => s.trim())
        : []
    }
    const response = await axios.post(
      `${BASE_URL}/projects/${projectId}/lists/${currentListId.value}/tasks`,
      { task: taskData },
      { headers: { Authorization: `Bearer ${token}` } }
    )

    const list = project.value.lists.find(l => l._id === currentListId.value)
    if (list) {
      if (!list.tasks) list.tasks = []
      list.tasks.push(response.data)
    }
    closeNewTaskModal()
    showSuccessToast(toast,'Tarea creada.')
  } catch (error) {
    console.error('Error al crear la tarea:', error)
    showErrorToast(toast,'Error al crear la tarea.')
  }
}



//Petición al endpoint para crear la lista con método POST
const createList = async () => {
  const title = newListTitle.value.trim()
  if (!title) return alert('El título de la lista es obligatorio')

  try {
    const order = project.value.lists.length
    const response = await axios.post(
      `${BASE_URL}/projects/${projectId}/lists`,
      { list: { title, order } },
      { headers: { Authorization: `Bearer ${token}` } }
    )

    //Añadimos la nueva lista al proyecto
    project.value.lists.push({ ...response.data, tasks: [] })

    //Inicializamos la tareas para esta lista
    newTask.value[response.data._id] = { title: '', description: '' }

    newListTitle.value = ''
    isCreatingList.value = false
    showSuccessToast(toast,'Lista creada.')
  } catch (error) {
    console.error('Error al crear lista:', error)
    showErrorToast(toast,'Error al crear la lista.')
  }
}
//Iniciamos la edición de la lista
const startEditList = (list) => {
  editingListId.value = list._id;
  editedListTitle.value = list.title;
  selectedListId.value = null;
};
//La cancelamos
const cancelEditList = () => {
  editingListId.value = null
  editedListTitle.value = ''
}
//Petición PUT para actualizar la lista
const updateList = async (listId) => {
  const newTitle = editedListTitle.value.trim()
  if (!newTitle) return alert('El título no puede estar vacío')

  try {
    const response = await axios.put(
      `${BASE_URL}/projects/${projectId}/lists/${listId}`,
      { list: { title: newTitle } },
      { headers: { Authorization: `Bearer ${token}` } }
    )

    const list = project.value.lists.find(l => l._id === listId)
    if (list) list.title = response.data.title

    cancelEditList()
    showSuccessToast(toast, 'Lista actualizada.')
  } catch (error) {
    console.error('Error al actualizar la lista:', error)
    showErrorToast(toast, 'Error al actualizar la lista.')
  }
}
//Petición DELETE para borrar la lista
const deleteList = async (listId) => {
  try {
    await axios.delete(
      `${BASE_URL}/projects/${projectId}/lists/${listId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    )

    project.value.lists = project.value.lists.filter(l => l._id !== listId)
    delete newTask.value[listId]
    showSuccessToast(toast,'Lista eliminada.')
  } catch (error) {
    console.error('Error al eliminar la lista:', error)
    showErrorToast(toast,'Error al eliminar la lista.')
  }
}
//Confirmación del delete
const confirmDeleteList = async (listId) => {
  const list = project.value.lists.find(l => l._id === listId)
  const taskCount = list.tasks?.length || 0

  const confirmMsg = `¿Estás seguro que quieres eliminar la lista "${list.title}" con ${taskCount} tarea(s)?`
  if (confirm(confirmMsg)) {
    await deleteList(listId)
  }
}
//Aquí realizamos la edición de la tarea, la actualizamos con los props pasados por Tasks
const editTask = async (updatedTask) => {
  try {
    const list = project.value.lists.find(l => l._id === updatedTask.list_id)
    if (!list) return alert('No se encontró la lista')

    const response = await axios.put(
      `${BASE_URL}/projects/${projectId}/lists/${updatedTask.list_id}/tasks/${updatedTask._id}`,
      { task: updatedTask },
      { headers: { Authorization: `Bearer ${token}` } }
    )


    const index = list.tasks.findIndex(t => t._id === updatedTask._id)
    if (index !== -1) {
      list.tasks[index] = response.data
      showSuccessToast(toast,'Tarea actualizada.')
    }
 
  } catch (error) {
    console.error('Error al editar la tarea:', error)
    showErrorToast(toast, 'Error al editar la tarea.')
  }
}

//Borramos la tarea con método DELETE
const deleteTask = async (taskId) => {
  try {
    const list = project.value.lists.find(l => l.tasks.some(t => t._id === taskId))
    if (!list) return alert('No se encontró la lista de la tarea')

    await axios.delete(
      `${BASE_URL}/projects/${projectId}/lists/${list._id}/tasks/${taskId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    )

 
    list.tasks = list.tasks.filter(t => t._id !== taskId)
    showSuccessToast(toast, 'Tarea eliminada.')
  } catch (error) {
    console.error('Error eliminando tarea:', error)
    showErrorToast(toast, 'Error al eliminar la tarea.')
  }
}

//Método onDrop para poder realizar el Draggable, comprobamos los ids para saber que no es la misma lista.
const onDrop = async (event) => {
  const movedTask = event.item?.__draggable_context?.element;
  const movedTaskId = movedTask?._id
  
  if (!movedTaskId || !movedTask) {
    console.error("ID de tarea no encontrado.")
    return
  }
  
  //Buscamos contenedor padre
  const originListEl = event.from.closest('.list-column')
  const destinationListEl = event.to.closest('.list-column')
  
  const originListId = originListEl ? originListEl.getAttribute('data-list-id') : null
  const destinationListId = destinationListEl ? destinationListEl.getAttribute('data-list-id') : null
  

  
  //Retornamos si el origen es igual al destino
  if (originListId === destinationListId) {
    return;
  }
  
  //Parseamos el JSON
  const rawMovedTask = JSON.parse(JSON.stringify(movedTask))
  
  //Actualizamos el list_id al de la lista destino
  rawMovedTask.list_id = destinationListId;
  

  //Petición put para actualizar el id de la lista a la que pertenece la tarea.
  try {

    const response = await axios.put(
      `${BASE_URL}/projects/${projectId}/lists/${originListId}/tasks/${movedTaskId}`,
      { task: rawMovedTask },
      { headers: { Authorization: `Bearer ${token}` } }
    );


    await fetchProjectLists();
  
  } catch (err) {
    console.error("Error al mover tarea:", err);
    showErrorToast(toast,'Error al mover la tarea')
  }
};
//Mostramos el menu
const toggleListMenu = (listId) => {
  selectedListId.value = selectedListId.value === listId ? null : listId;
};


onMounted(fetchProjectLists)
</script>

<style scoped>

.project-lists {
  padding: 1rem;
  position: relative;
  display: flex;
  flex-direction: column;
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  margin-top: 1.5rem;
  border-radius: 10px;
  background-color: #f1eee1;
  color: #333;
  height: calc(100vh - 60px); 
  overflow: hidden;
}


.project-lists > h1 {
  font-size: 1.8rem;
  margin-bottom: 0.5rem;
}

.project-lists > p {
  font-size: 1rem;
  color: #666;
  margin-bottom: 1rem;
}

.lists-container {
  display: flex;
  gap: 1rem;
  overflow-x: auto;
  padding-bottom: 1rem;
  flex: 1;
}

.list-column {
  background-color: #fff; 
  border-radius: 12px;      
  padding: 1rem;          
  min-width: 250px;
  max-width: 300px;
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1); 
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.list-column:hover {
  transform: translateY(-4px);
}

.list-column h3 {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
}

.list-column button {
  background: none;
  border: none;
  cursor: pointer;
  padding: 2px;
}

.list-column > div[data-task-id] {
  background: white;
  padding: 0.5rem;
  margin-bottom: 0.5rem;
  border-radius: 4px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.1);
  position: relative;
  transition: 0.2s ease;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.list-column > div[data-task-id]:hover button {
  opacity: 1;
}

.list-column > div[data-task-id] button {
  opacity: 0;
  transition: opacity 0.2s;
}

.new-task-form {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 1rem;
}

.new-task-form input,
.new-task-form textarea {
  padding: 0.5rem;
  border-radius: 4px;
  border: 1px solid #ccc;
  font-size: 1rem;
  background-color: #fff;
  color: #333;
}

.new-task-form input:focus,
.new-task-form textarea:focus {
  border-color: #61c081;
  outline: none;
}


.new-task-form button {
  align-self: flex-start;
  background-color: #1976d2;
  color: white;
  border: none;
  padding: 0.4rem 0.8rem;
  border-radius: 4px;
  cursor: pointer;
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

button:hover:not(:disabled) {
  background-color: #1565c0;
}

button:focus {
  outline: none;
}

.project-lists > button {
  position: absolute;
  bottom: 1.5rem;
  right: 1.5rem;
  background-color: #61c081; 
  color: white;
  padding: 0.7rem 1rem;
  border-radius: 50px;
  font-weight: bold;
  border: none;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  transition: background-color 0.2s ease;
}

.project-lists > button:hover {
  background-color: #2e7d32;
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
  position: relative;
}

.list-title {
  font-size: 1.1rem;
  font-weight: bold;
  width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.list-menu {
  font-size: 1.2rem;
  cursor: pointer;
}


.list-actions {
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

.dropdown {
  position: relative;
  display: inline-block;
}

.dropdown-menu {
  position: absolute;
  top: 110%; 
  right: 0;
  background-color: #fff;
  border: 1px solid #ccc;
  border-radius: 4px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  padding: 0.5rem 0;
  z-index: 10;
}

.dropdown-menu button {
  display: block;
  width: 100%;
  padding: 0.5rem 1rem;
  background: none;
  border: none;
  text-align: left;
  cursor: pointer;
}

.dropdown-menu button:hover {
  background-color: #f1f1f1;
}


.edit-btn {
  color: #007bff;
}

.delete-btn {
  color: #dc3545;
}

.edit-btn:hover,
.delete-btn:hover {
  text-decoration: none;
}

.edit-mode {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}


.edit-input {
  flex-grow: 1; 
  padding: 0.4rem;
  font-size: 1rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  background-color: #fff;
  color: #333;
  outline: none;
}


.save-btn,
.cancel-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent; 
  cursor: pointer;
  font-size: 1.2rem; 
  padding: 0.2rem;
}


.save-btn {
  color: #61c081;
}


.cancel-btn {
  color: #dc3545;
}


.save-btn i,
.cancel-btn i {
  transition: transform 0.2s ease;
}


.save-btn:hover,
.cancel-btn:hover {
  background-color: rgba(0, 0, 0, 0.05) !important; 
}


.save-btn:hover i,
.cancel-btn:hover i {
  transform: scale(1.2);
}


.new-task-btn {
  margin-top: 0.5rem;
  padding: 0.5rem 1rem;
  background-color: #61c081;
  color: #fff;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}


.dialog-content {
  background-color: #f9f9f9;
  border: 1px solid #61c081;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 1rem;
  border-radius: 15px;
}

.new-task-btn {
  margin-top: 0.5rem;
  padding: 0.5rem 1rem;
  background-color: #61c081;
  color: #fff;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}


.dialog-content {
  background-color: #f9f9f9;
  border: 1px solid #61c081;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 0.8rem;
  border-radius: 15px;
}

.new-task-modal-content {
  display: flex;
  flex-direction: row;
  gap: 2rem; 
}

.new-task-modal-content .col {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.field {
  margin-bottom: 1rem;
}

.field label {
  font-weight: bold;
  margin-bottom: 0.25rem;
  display: block;
}

.edit-input {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}


.dialog-content {
  background-color: #f9f9f9;
  border: 1px solid #61c081;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 1rem;
  border-radius: 15px;
}
.dialog-header {
  color: black;
}

.modal-buttons {
  margin-top: 1rem;
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}
::v-deep(.p-inputtext) {
  background-color: white !important;
  color: black !important;
}

.back-btn {
  position: fixed;
  bottom: 1.5rem;
  left: 1.5rem;
  background-color: #61c081; 
  color: white;
  padding: 0.7rem 1rem;
  border-radius: 50px;
  font-weight: bold;
  border: none;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  transition: background-color 0.2s ease;
  z-index: 1000;
}

.back-btn:hover {
  background-color: #2e7d32;
}
</style>