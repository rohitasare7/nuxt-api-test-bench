<script setup lang="ts">
const user = useSupabaseUser()

watch(user, () => {
  if (user.value) {
    return navigateTo('/')
  }
}, { immediate: true })
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-background text-foreground">
    <div class="text-center space-y-4">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
      <p class="text-muted-foreground">Verifying authentication...</p>
    </div>
  </div>
</template>
