export function showSuccessToast(toast, detail = 'Operación realizada exitosamente.') {
    toast.add({
      severity: 'success',
      summary: 'Éxito',
      detail,
      life: 3000
    });
  }
  
  export function showErrorToast(toast, detail = 'Ocurrió un error.') {
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail,
      life: 3000
    });
  }
  