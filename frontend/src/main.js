import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import Toast from 'primevue/toast'
import ConfirmationService from 'primevue/confirmationservice';
import 'primeicons/primeicons.css'
import Nora from '@primevue/themes/nora';

createApp(App)
.use(router)
.use(PrimeVue, {
    theme:{
        preset: Nora,
    },
})
.use(ToastService)
.use(ConfirmationService)
.component('Toast',Toast)
.mount('#app')
