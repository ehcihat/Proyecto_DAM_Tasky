import { createRouter, createWebHistory } from 'vue-router';
import Register from '../../src/components/Register.vue'; 
import Login from '../components/Login.vue';
import Projects from '../components/Projects.vue';
import Tasks from '../components/Tasks.vue'; 
import Lists from '../components/Lists.vue';
const routes = [
{ path: '/', redirect: '/projects' },
{path: '/register', name: 'Register', component: Register, meta: {title: 'Registro'}},
{path: '/login', name: 'Login', component: Login, meta: {title: 'Inicio de sesión'}},
{path: '/projects', name: 'Proyectos', component: Projects, meta: {title: 'Proyectos',requiresAuth: true}},
{ path: '/projects/:projectId/lists/:listId/tasks', name: 'Tasks', component: Tasks, meta: { title: 'Tareas', requiresAuth: true } },
{ path: '/projects/:projectId/lists', name: 'Lists', component: Lists, meta: { title: 'Listas del Proyecto', requiresAuth: true } },
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
});

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token');


   if (to.meta.requiresAuth && !token) {
    next('/login');
  } else {

    if (to.meta.title) {
      document.title = to.meta.title;
    } else {
      document.title = 'Mi Aplicación'; 
      next('/login');
    }
    next();
  }
});

export default router;
