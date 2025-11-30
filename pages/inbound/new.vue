<script setup lang="ts">
import { ArrowLeft, Save, Key } from 'lucide-vue-next'

definePageMeta({
  middleware: 'auth'
})

const client = useSupabaseClient()
const user = useSupabaseUser()
const router = useRouter()

const form = ref({
  path: '',
  method: 'GET',
  response_status: 200,
  response_body: '{\n  "message": "Hello World"\n}',
  auth_token: ''
})

const loading = ref(false)
const error = ref('')
const suggestion = ref('')

const generateToken = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let token = ''
  for (let i = 0; i < 32; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  form.value.auth_token = token
}

const checkDuplicate = async () => {
  suggestion.value = ''
  
  if (!form.value.path) return
  
  let path = form.value.path
  if (!path.startsWith('/')) path = '/' + path
  
  const { data } = await client
    .from('inbound_apis')
    .select('path, method')
    .eq('path', path)
    .eq('method', form.value.method)
    .single()
  
  if (data) {
    // Path exists, suggest alternatives
    const basePath = path.replace(/\d+$/, '') // Remove trailing numbers
    let counter = 1
    let suggestedPath = `${basePath}${counter}`
    
    // Keep checking until we find an available path
    while (true) {
      const { data: checkData } = await client
        .from('inbound_apis')
        .select('path')
        .eq('path', suggestedPath)
        .eq('method', form.value.method)
        .single()
      
      if (!checkData) break
      counter++
      suggestedPath = `${basePath}${counter}`
    }
    
    suggestion.value = suggestedPath
    error.value = `This path already exists. Try: ${suggestedPath}`
  }
}

const save = async () => {
  loading.value = true
  error.value = ''
  suggestion.value = ''

  try {
    // Validate JSON
    JSON.parse(form.value.response_body)

    // Ensure path starts with /
    let path = form.value.path
    if (!path.startsWith('/')) path = '/' + path

    let userId = user.value?.id

    // Fallback: Try to get user directly from client
    if (!userId) {
      const { data } = await client.auth.getUser()
      userId = data.user?.id
    }

    // Guest user fallback for testing
    if (!userId) {
      userId = null // Set to null for guest
    }

    console.log('Saving API:', {
      user_id: userId,
      path,
      method: form.value.method
    })

    const { error: insertError } = await client.from('inbound_apis').insert({
      user_id: userId,
      path,
      method: form.value.method,
      response_status: form.value.response_status,
      response_body: JSON.parse(form.value.response_body),
      auth_token: form.value.auth_token || null
    })

    if (insertError) {
      if (insertError.code === '23505') { // Unique constraint violation
        await checkDuplicate()
        throw new Error(`This path already exists. Try: ${suggestion.value}`)
      }
      throw insertError
    }

    router.push('/inbound')
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="p-8 max-w-4xl mx-auto space-y-6">
    <div class="flex items-center gap-4">
      <NuxtLink to="/inbound" class="p-2 hover:bg-accent rounded-full transition-colors">
        <ArrowLeft class="w-5 h-5" />
      </NuxtLink>
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Create Inbound API</h1>
        <p class="text-muted-foreground mt-1">Define a new mock endpoint</p>
      </div>
    </div>

    <div class="bg-card border border-border rounded-xl p-6 space-y-6 shadow-sm">
      <div v-if="error" class="p-4 bg-destructive/10 text-destructive rounded-lg text-sm font-medium">
        {{ error }}
      </div>

      <div class="grid gap-6 md:grid-cols-2">
        <div class="space-y-2">
          <label class="text-sm font-medium">Method</label>
          <select v-model="form.method" class="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-ring">
            <option value="GET">GET</option>
            <option value="POST">POST</option>
            <option value="PUT">PUT</option>
            <option value="DELETE">DELETE</option>
            <option value="PATCH">PATCH</option>
          </select>
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium">Response Status</label>
          <input type="number" v-model="form.response_status" class="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-ring" />
        </div>
      </div>

      <div class="space-y-2">
        <label class="text-sm font-medium">Path</label>
        <div class="flex items-center gap-2">
          <span class="text-muted-foreground text-sm">/api/mock</span>
          <input 
            type="text" 
            v-model="form.path" 
            @blur="checkDuplicate"
            placeholder="/users/123" 
            class="flex-1 px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-ring" 
          />
        </div>
        <div v-if="suggestion" class="flex items-center gap-2">
          <p class="text-xs text-muted-foreground">Suggestion:</p>
          <button 
            @click="form.path = suggestion; suggestion = ''; error = ''"
            class="text-xs px-2 py-1 bg-accent hover:bg-accent/80 rounded"
          >
            Use {{ suggestion }}
          </button>
        </div>
      </div>

      <div class="space-y-2">
        <label class="text-sm font-medium">Authentication Token (Optional)</label>
        <div class="flex gap-2">
          <input 
            type="text" 
            v-model="form.auth_token" 
            placeholder="Leave empty for public access" 
            class="flex-1 px-3 py-2 bg-background border border-border rounded-md font-mono text-sm focus:outline-none focus:ring-2 focus:ring-ring" 
          />
          <button 
            @click="generateToken" 
            type="button"
            class="flex items-center gap-2 px-4 py-2 bg-accent hover:bg-accent/80 rounded-md transition-colors"
          >
            <Key class="w-4 h-4" />
            Generate
          </button>
        </div>
        <p class="text-xs text-muted-foreground">If set, requests must include header "authorization" with value of this token.</p>
      </div>

      <div class="space-y-2">
        <label class="text-sm font-medium">Response Body (JSON)</label>
        <textarea v-model="form.response_body" rows="10" class="w-full px-3 py-2 bg-background border border-border rounded-md font-mono text-sm focus:outline-none focus:ring-2 focus:ring-ring"></textarea>
      </div>

      <div class="flex justify-end pt-4">
        <button @click="save" :disabled="loading" class="flex items-center gap-2 px-6 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors disabled:opacity-50">
          <Save class="w-4 h-4" />
          {{ loading ? 'Saving...' : 'Create API' }}
        </button>
      </div>
    </div>
  </div>
</template>
