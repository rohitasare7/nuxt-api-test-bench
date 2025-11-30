<script setup lang="ts">
import { LayoutDashboard, ArrowDownLeft, ArrowUpRight, LogOut } from 'lucide-vue-next'
const user = useSupabaseUser()
const client = useSupabaseClient()
const router = useRouter()

const logout = async () => {
  await client.auth.signOut()
  router.push('/login')
}
</script>

<template>
  <div class="min-h-screen bg-background text-foreground flex">
    <!-- Sidebar -->
    <aside class="w-64 border-r border-border bg-card flex flex-col">
      <div class="p-6 border-b border-border">
        <h1 class="text-xl font-bold bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
          VibeTester
        </h1>
      </div>
      
      <nav class="flex-1 p-4 space-y-2">
        <NuxtLink to="/" class="flex items-center gap-3 px-4 py-2 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors" active-class="bg-accent text-accent-foreground">
          <LayoutDashboard class="w-5 h-5" />
          Dashboard
        </NuxtLink>
        <NuxtLink to="/inbound" class="flex items-center gap-3 px-4 py-2 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors" active-class="bg-accent text-accent-foreground">
          <ArrowDownLeft class="w-5 h-5" />
          Inbound APIs
        </NuxtLink>
        <NuxtLink to="/outbound" class="flex items-center gap-3 px-4 py-2 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors" active-class="bg-accent text-accent-foreground">
          <ArrowUpRight class="w-5 h-5" />
          Outbound APIs
        </NuxtLink>
      </nav>

      <div class="p-4 border-t border-border">
        <div v-if="user" class="flex items-center gap-3 mb-4 px-2">
          <img :src="user.user_metadata.avatar_url || 'https://github.com/shadcn.png'" class="w-8 h-8 rounded-full" />
          <div class="flex-1 overflow-hidden">
            <p class="text-sm font-medium truncate">{{ user.email }}</p>
          </div>
        </div>
        <button @click="logout" class="w-full flex items-center justify-center gap-2 px-4 py-2 rounded-md border border-border hover:bg-accent hover:text-accent-foreground transition-colors text-sm">
          <LogOut class="w-4 h-4" />
          Sign Out
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 overflow-auto">
      <slot />
    </main>
  </div>
</template>
