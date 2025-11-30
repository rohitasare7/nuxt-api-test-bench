<script setup lang="ts">
import { Plus, Trash2, Copy, ExternalLink, Edit, Lock } from 'lucide-vue-next'

definePageMeta({
  middleware: 'auth'
})

const client = useSupabaseClient()
const user = useSupabaseUser()
const apis = ref([])

const fetchApis = async () => {
  const { data, error } = await client
    .from('inbound_apis')
    .select('*')
    .order('created_at', { ascending: false })
  
  if (data) apis.value = data
}

onMounted(() => {
  fetchApis()
})

const deleteApi = async (id: string) => {
  if (!confirm('Are you sure?')) return
  await client.from('inbound_apis').delete().match({ id })
  fetchApis()
}

const copyUrl = async (path: string) => {
  const url = `${window.location.origin}/api/mock${path}`
  navigator.clipboard.writeText(url)
  alert('Copied to clipboard!')
}

const copyToken = async (token: string) => {
  navigator.clipboard.writeText(token)
  alert('Token copied to clipboard!')
}
</script>

<template>
  <div class="p-8 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Inbound APIs</h1>
        <p class="text-muted-foreground mt-1">Manage your mock endpoints</p>
      </div>
      <NuxtLink to="/inbound/new" class="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors">
        <Plus class="w-4 h-4" />
        Create New
      </NuxtLink>
    </div>

    <div v-if="apis.length === 0" class="text-center py-12 border border-dashed border-border rounded-xl">
      <p class="text-muted-foreground">No APIs created yet.</p>
    </div>

    <div v-else class="grid gap-4">
      <div v-for="api in apis" :key="api.id" class="p-6 rounded-xl border border-border bg-card text-card-foreground shadow-sm flex items-center justify-between group">
        <div class="space-y-1">
          <div class="flex items-center gap-3">
            <span :class="{
              'px-2 py-0.5 rounded text-xs font-bold uppercase': true,
              'bg-green-500/10 text-green-500': api.method === 'GET',
              'bg-blue-500/10 text-blue-500': api.method === 'POST',
              'bg-yellow-500/10 text-yellow-500': api.method === 'PUT',
              'bg-red-500/10 text-red-500': api.method === 'DELETE',
            }">{{ api.method }}</span>
            <code class="text-sm bg-muted px-2 py-0.5 rounded">{{ api.path }}</code>
            <span v-if="api.auth_token" class="flex items-center gap-1 px-2 py-0.5 rounded text-xs bg-orange-500/10 text-orange-500" title="Protected with authentication">
              <Lock class="w-3 h-3" />
              Protected
            </span>
          </div>
          <div v-if="api.auth_token" class="flex items-center gap-2 mt-1">
            <code class="text-xs bg-muted px-2 py-0.5 rounded font-mono">{{ api.auth_token }}</code>
            <button @click="copyToken(api.auth_token)" class="text-xs text-muted-foreground hover:text-foreground" title="Copy token">
              <Copy class="w-3 h-3" />
            </button>
          </div>
          <p class="text-xs text-muted-foreground">Created {{ new Date(api.created_at).toLocaleDateString() }}</p>
        </div>
        
        <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
          <button @click="copyUrl(api.path)" class="p-2 hover:bg-accent rounded-md" title="Copy URL">
            <Copy class="w-4 h-4" />
          </button>
          <NuxtLink :to="`/inbound/edit/${api.id}`" class="p-2 hover:bg-accent rounded-md" title="Edit">
            <Edit class="w-4 h-4" />
          </NuxtLink>
          <button @click="deleteApi(api.id)" class="p-2 hover:bg-destructive/10 hover:text-destructive rounded-md" title="Delete">
            <Trash2 class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
