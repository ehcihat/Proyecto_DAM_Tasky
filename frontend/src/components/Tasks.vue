<template>
  <div
    class="task-card"
    ref="card"
    @click="toggleInfo"
    :class="{ active: isInfoVisible }"
  >
    <!--Vista de la tarea-->
    <div class="display-mode">
      <span class="task-title" :class="{ completed: task.completed }">
        {{ task.title }}
      </span>
      <div class="progress-container" @click.stop>
        <div class="progress-label">
          Progreso: {{ currentProgress }}%
        </div>
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: currentProgress + '%' }"></div>
        </div>
        <input
          type="range"
          min="0"
          max="100"
          v-model.number="currentProgress"
          @change.stop="updateProgress"
        />
      </div>
      <div class="task-actions">
        <i class="pi pi-pencil edit-icon" @click.stop="startEditing" title="Editar tarea"></i>
        <Checkbox
          v-model="checked"
          title="Completar"
          binary
          @click.stop
          @change.stop="toggleTaskCompletion"
        />
        <i
          class="pi pi-trash delete-icon"
          @click.stop="confirmDelete"
          title="Borrar tarea"
        ></i>
      </div>
    </div>

    <!-- Detalles de la tarea-->
    <div class="hover-details">
      <p><strong>Descripción:</strong> {{ task.description || 'Sin descripción' }}</p>
      <p>
        <strong>Fecha:</strong>
        {{ task.due_date ? new Date(task.due_date).toLocaleString() : 'Sin fecha' }}
      </p>
      <p>
        <strong>Comentarios:</strong>
        {{ task.comments && task.comments.length ? task.comments.join(', ') : 'Sin comentarios' }}
      </p>
    </div>

    <!--Dialogo de editar la tarea-->
    <Dialog 
      v-model:visible="isEditing" 
      header="Editar tarea" 
      modal 
      :closable="false"
      contentClass="dialog-content"
    >
      <div class="modal-content">
        <!--Título y descripción -->
        <div class="title-des">
          <div class="field">
            <label for="title">Título</label>
            <input 
              id="title" 
              v-model="editedTitle" 
              type="text" 
              class="edit-input" 
              placeholder="Editar título" 
            />
          </div>
          <div class="field">
            <label for="description">Descripción</label>
            <textarea 
              id="description" 
              v-model="editedDescription" 
              rows="4" 
              class="edit-input" 
              placeholder="Editar descripción"
            ></textarea>
          </div>
        </div>
    
        <!-- Calendario y comentarios -->
        <div class="cal-coment">
          <div class="field">
            <label for="due-date">Fecha y hora de vencimiento</label>
            <DatePicker 
              v-model="editedDueDate" 
              :showTime="true" 
              hourFormat="24" 
              format="dd/MM/yy HH:mm" 
              class="edit-input" 
            />
          </div>
          <div class="field">
            <label for="comments">Comentarios</label>
            <textarea 
              id="comments" 
              v-model="editedComments" 
              rows="4" 
              class="edit-input" 
              placeholder="Editar comentarios"
            ></textarea>
          </div>
        </div>
      </div>
      <div class="modal-buttons">
        <button class="save-btn" @click="saveTask">
          <i class="pi pi-check"></i> Guardar
        </button>
        <button class="cancel-btn" @click="cancelEdit">
          <i class="pi pi-times"></i> Cancelar
        </button>
      </div>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, watch, defineProps, defineEmits } from 'vue'
import axios from 'axios'
import { useRoute } from 'vue-router'
import Checkbox from 'primevue/checkbox'
import Dialog from 'primevue/dialog'
import DatePicker from 'primevue/datepicker'

const isInfoVisible = ref(false)
const BASE_URL = 'http://localhost:3000'

//Definimos las props.
const props = defineProps({
  task: { type: Object, required: true },
  listId: { type: String, required: true }
})
//Las emitimos.
const emit = defineEmits(['editTask', 'deleteTask', 'setEditing'])


//Prop para verificar si está checkeado o no
const checked = ref(props.task.completed)
watch(() => props.task.completed, (newVal) => {
  checked.value = newVal
})


//Prop para el progreso
const currentProgress = ref(props.task.progress || 0)

const route = useRoute()
const projectId = route.params.projectId
const token = localStorage.getItem('token')

//Referenciamos la card para animaciones
const card = ref(null)

//Variables para el modal de edición
const isEditing = ref(false)
const editedTitle = ref('')
const editedDescription = ref('')
const editedDueDate = ref(props.task.due_date ? new Date(props.task.due_date) : null)
const editedComments = ref(props.task.comments ? props.task.comments.join(', ') : '')

const toggleInfo = () => {
  isInfoVisible.value = !isInfoVisible.value
}
//Comenzamos edición
const startEditing = () => {
  isEditing.value = true
  editedTitle.value = props.task.title
  editedDescription.value = props.task.description || ''
  editedDueDate.value = props.task.due_date ? new Date(props.task.due_date) : null
  editedComments.value = props.task.comments ? props.task.comments.join(', ') : ''
  emit('setEditing', true)
}
//Cancelar edición
const cancelEdit = () => {
  isEditing.value = false
  editedTitle.value = ''
  editedDescription.value = ''
  editedDueDate.value = null
  editedComments.value = ''
  emit('setEditing', false)
}
//Función para editar la tarea y pasamos los props de la edición a Lists.vue
const saveTask = async () => {
  if (!editedTitle.value.trim()) {
    alert('El título no puede estar vacío')
    return
  }
  try {
    const updatedTask = {
      title: editedTitle.value.trim(),
      description: editedDescription.value.trim(),
      due_date: editedDueDate.value ? editedDueDate.value.toISOString() : null,
      comments: editedComments.value 
        ? editedComments.value.split(',').map(s => s.trim())
        : []
    }
    const response = await axios.put(
      `${BASE_URL}/projects/${projectId}/lists/${props.listId}/tasks/${props.task._id}`,
      { task: updatedTask },
      { headers: { Authorization: `Bearer ${token}` } }
    )
    emit('editTask', response.data)
    isEditing.value = false
    emit('setEditing', false)
  } catch (error) {
    console.error('Error al actualizar la tarea:', error)
  }
}
//Modifica las props de la tarea según si se ha dado check al botón o a la barra de progreso.
const toggleTaskCompletion = async () => {
  try {

    const newCompleted = !props.task.completed;
    const newProgress = newCompleted ? 100 : 0; 
    const updatedTask = { completed: newCompleted, progress: newProgress };
    const _listId = props.task.list_id || props.listId;

    const response = await axios.put(
      `${BASE_URL}/projects/${projectId}/lists/${_listId}/tasks/${props.task._id}`,
      { task: updatedTask },
      { headers: { Authorization: `Bearer ${token}` } }
    );

    props.task.completed = response.data.completed;
    checked.value = response.data.completed;
    props.task.progress = response.data.progress;
    currentProgress.value = response.data.progress;

    if (card.value) {
      card.value.classList.add('animate');
      setTimeout(() => {
        card.value && card.value.classList.remove('animate');
        if (props.task.completed) {
          card.value.style.backgroundColor = '#e8f5e9';
          card.value.style.borderColor = '#66bb6a';
        } else {
          card.value.style.backgroundColor = '#f9f9f9';
          card.value.style.borderColor = '#61c081';
        }
      }, 500);
    }

    const audio = new Audio('/sounds/completed.mp3');
    audio.play();

  } catch (error) {
    console.error('Error al actualizar tarea:', error);
  }
}
//Función en la que llamamos para hacer la actualización de la barra de progreso de la tarea
const updateProgress = async () => {
  try {

    const newProgress = Number(currentProgress.value);
    const newCompleted = newProgress === 100;
    const updatedTask = { progress: newProgress, completed: newCompleted };
    const _listId = props.task.list_id || props.listId;

    const response = await axios.put(
      `${BASE_URL}/projects/${projectId}/lists/${_listId}/tasks/${props.task._id}`,
      { task: updatedTask },
      { headers: { Authorization: `Bearer ${token}` } }
    );


    props.task.progress = response.data.progress;
    currentProgress.value = response.data.progress;
    props.task.completed = response.data.completed;
    checked.value = response.data.completed;


    if ((newCompleted || newProgress === 0 || newProgress<100) && card.value) {
      card.value.classList.add('animate');
      setTimeout(() => {
        if (card.value) {
          card.value.classList.remove('animate');
         
          if (newCompleted) {
            card.value.style.backgroundColor = '#e8f5e9';
            card.value.style.borderColor = '#66bb6a';
          } else {
            card.value.style.backgroundColor = '#f9f9f9';
            card.value.style.borderColor = '#61c081';
          }
        }
      }, 500);

      const audio = new Audio('/sounds/completed.mp3');
      audio.play();
    }
  } catch (error) {
    console.error('Error al actualizar el progreso de la tarea:', error);
  }
};
//Ventana para confirmar si se quiere borrar la tareita.
const confirmDelete = () => {
  const confirmMsg = `¿Estás seguro que deseas eliminar la tarea "${props.task.title}"?`
  if (confirm(confirmMsg)) {
    emit('deleteTask', props.task._id)
  }
}
</script>

<style scoped>
.task-card {
  position: relative;
  background-color: #f9f9f9;
  border: 1px solid #61c081;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 0.8rem;
  margin-bottom: 10px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-radius: 15px;
  transition: transform 0.2s ease;
}

@keyframes pulse {
  0% {
    transform: scale(1);
    background-color: #f9f9f9;
  }
  50% {
    transform: scale(1.1);
    background-color: #e8f5e9;
  }
  100% {
    transform: scale(1);
    background-color: #e8f5e9;
  }
}

.animate {
  animation: pulse 0.5s ease forwards;
}

.display-mode {
  width: 100%;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
}

.task-title {
  font-size: 1rem;
  flex-grow: 1;
}

.task-title.completed {
  text-decoration: line-through;
  opacity: 0.7;
}

.task-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.edit-icon {
  cursor: pointer;
  font-size: 1.2rem;
}

.edit-mode {
  width: 100%;
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
  outline: none;
}

.save-btn,
.cancel-btn {
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: 1.2rem;
  padding: 0.3rem;
  transition: transform 0.2s ease, background-color 0.2s;
}

.save-btn:hover,
.cancel-btn:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

.save-btn:hover i,
.cancel-btn:hover i {
  transform: scale(1.2);
}

button::-moz-focus-inner {
  border: 0;
  padding: 0;
}

button:focus,
button:active,
button i:focus,
button i:active {
  outline: none;
  background: transparent !important;
}

:deep(.p-checkbox .p-checkbox-box) {
  background-color: white !important;
  border-color: #ccc !important;
}

.delete-icon {
  color: #e53935;
  font-size: 1.2rem;
  cursor: pointer;
  opacity: 0.7;
  transition: opacity 0.2s ease, transform 0.2s ease;
  margin-left: 0.5rem;
}

.delete-icon:hover {
  opacity: 1;
  transform: scale(1.1);
}


.dialog-content {
  background-color: #f9f9f9;
  border: 1px solid #61c081;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 0.8rem;
  border-radius: 15px;
}


.modal-content {
  display: flex;
  gap: 1rem;
}

.title-des,
.cal-coment {
  flex: 1;
}

.field {
  margin-bottom: 1rem;
}

.field label {
  display: block;
  margin-bottom: 0.25rem;
  font-weight: bold;
}

.modal-buttons {
  margin-top: 1rem;
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}

.desc-label {
  margin-top: 1rem;
}

.p-dialog {
  background-color: white !important;
  color: black !important;
}

.p-dialog .p-dialog-header,
.p-dialog .p-dialog-content {
  background-color: white !important;
  color: black !important;
}

.p-dialog .p-inputtext,
.p-dialog textarea,
.p-dialog input {
  background-color: white !important;
  color: black !important;
  border: 1px solid #ccc !important;
}
::v-deep(.p-inputtext) {
  background-color: white !important;
  color: black !important;
}


.hover-details {
  position: absolute;
  top: 100%;
  left: 0;
  width: 100%;
  background-color: rgba(255, 255, 255, 0.95);
  border: 1px solid #ccc;
  border-radius: 4px;
  padding: 0.5rem;
  box-shadow: 0 2px 5px rgba(0,0,0,0.2);
  z-index: 10;
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.3s ease, visibility 0.3s ease;
}


.task-card.active .hover-details {
  opacity: 1;
  visibility: visible;
}

.progress-container {
  display: flex;
  flex-direction: column;
  gap: 4px;
  width: 60%; 
  margin-top: 8px;
}

.progress-label {
  font-size: 0.9rem;
  margin-bottom: 4px;
}


.progress-bar {
  width: 100%;
  height: 12px; 
  background-color: #eee;
  border-radius: 20px;
  overflow: hidden;
  margin-bottom: 8px;
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.12);
}


.progress-fill {
  height: 100%;
  border-radius: 20px;

  background: linear-gradient(45deg, #3ea2ca, #3da726);
  transition: width 0.4s ease;
  box-shadow: 0 2px 3px rgba(0, 0, 0, 0.2);
}

@media (max-width: 600px) {
  .display-mode {
    flex-direction: column;
    align-items: flex-start;
  }

  .progress-container {
    width: 100%; 
    margin-top: 8px;
  }

  .task-actions {
    align-self: stretch;
    justify-content: flex-end;
    width: 100%;
    margin-top: 8px;
  }

  
}
</style>
