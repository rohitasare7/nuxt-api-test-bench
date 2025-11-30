<script setup lang="ts">
import { Play, Save, Clock, Plus, Trash2 } from 'lucide-vue-next'

definePageMeta({
  middleware: 'auth'
})

const url = ref('https://jsonplaceholder.typicode.com/todos/1')
const method = ref('GET')
const headers = ref([{ key: '', value: '' }])
const body = ref('')
const name = ref('')
const response = ref<any>(null)
const loading = ref(false)

const addHeader = () => headers.value.push({ key: '', value: '' })
const removeHeader = (index: number) => headers.value.splice(index, 1)

const sendRequest = async () => {
  loading.value = true
  response.value = null
  
  try {
    const headerObj = headers.value.reduce((acc: any, curr) => {
      if (curr.key) acc[curr.key] = curr.value
      return acc
    }, {})

    const res = await $fetch('/api/proxy', {
      method: 'POST',
      body: {
        url: url.value,
        method: method.value,
        headers: headerObj,
        body: body.value ? JSON.parse(body.value) : undefined,
        name: name.value || undefined
      }
    })
    
    response.value = res
  } catch (e) {
    console.error(e)
    response.value = { error: 'Failed to send request' }
  } finally {
    loading.value = false
  }
}

const formattedJson = computed(() => {
  if (!response.value?.data) return ''
  return JSON.stringify(response.value.data, null, 2)
})
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="p-4 border-b border-border flex items-center gap-4 bg-card">
      <select v-model="method" class="px-3 py-2 bg-background border border-border rounded-md font-bold w-24">
        <option value="GET" class="text-green-500">GET</option>
        <option value="POST" class="text-blue-500">POST</option>
        <option value="PUT" class="text-yellow-500">PUT</option>
        <option value="DELETE" class="text-red-500">DELETE</option>
      </select>
      
      <input type="text" v-model="url" placeholder="Enter URL" class="flex-1 px-3 py-2 bg-background border border-border rounded-md" />
      
      <button @click="sendRequest" :disabled="loading" class="px-6 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors flex items-center gap-2 font-medium">
        <Play class="w-4 h-4" :class="{ 'animate-spin': loading }" v-if="loading" />
        <Play class="w-4 h-4" v-else />
        Send
      </button>
    </div>

    <div class="flex-1 flex overflow-hidden">
      <!-- Request Panel -->
      <div class="w-1/2 border-r border-border flex flex-col">
        <div class="p-4 border-b border-border">
          <h2 class="font-semibold mb-4">Request</h2>
          
          <div class="space-y-4">
            <div>
              <label class="text-sm font-medium mb-2 block">Headers</label>
              <div class="space-y-2">
                <div v-for="(header, index) in headers" :key="index" class="flex gap-2">
                  <input v-model="header.key" placeholder="Key" class="flex-1 px-2 py-1 bg-background border border-border rounded text-sm" />
                  <input v-model="header.value" placeholder="Value" class="flex-1 px-2 py-1 bg-background border border-border rounded text-sm" />
                  <button @click="removeHeader(index)" class="p-1 hover:bg-destructive/10 hover:text-destructive rounded">
                    <Trash2 class="w-4 h-4" />
                  </button>
                </div>
                <button @click="addHeader" class="text-xs flex items-center gap-1 text-muted-foreground hover:text-foreground">
                  <Plus class="w-3 h-3" /> Add Header
                </button>
              </div>
            </div>

            <div>
              <label class="text-sm font-medium mb-2 block">Body (JSON)</label>
              <textarea v-model="body" rows="10" class="w-full px-3 py-2 bg-background border border-border rounded-md font-mono text-sm resize-none"></textarea>
            </div>
            
            <div>
               <label class="text-sm font-medium mb-2 block">Save as (Optional)</label>
               <input v-model="name" placeholder="Request Name" class="w-full px-3 py-2 bg-background border border-border rounded-md text-sm" />
            </div>
          </div>
        </div>
      </div>

      <!-- Response Panel -->
      <div class="w-1/2 flex flex-col bg-muted/10">
        <div class="p-4 border-b border-border flex items-center justify-between">
          <h2 class="font-semibold">Response</h2>
          <div v-if="response" class="flex items-center gap-4 text-sm">
            <span :class="{
              'text-green-500': response.status >= 200 && response.status < 300,
              'text-yellow-500': response.status >= 300 && response.status < 400,
              'text-red-500': response.status >= 400
            }">Status: {{ response.status }}</span>
            <span class="flex items-center gap-1 text-muted-foreground">
              <Clock class="w-3 h-3" /> {{ response.duration }}ms
            </span>
          </div>
        </div>

        <div class="flex-1 p-4 overflow-auto">
          <div v-if="!response && !loading" class="h-full flex items-center justify-center text-muted-foreground">
            Enter a URL and click Send
          </div>
          
          <div v-else-if="loading" class="h-full flex items-center justify-center text-muted-foreground">
            Sending request...
          </div>

          <div v-else class="space-y-4">
            <pre class="bg-card p-4 rounded-lg border border-border overflow-auto text-xs font-mono whitespace-pre-wrap">{{ JSON.stringify(response.data, null, 2) }}</pre>
            
            <div class="space-y-2">
               <h3 class="text-sm font-medium">Headers</h3>
               <div class="grid grid-cols-2 gap-2 text-xs">
                 <div v-for="(value, key) in response.headers" :key="key" class="p-2 bg-card border border-border rounded">
                   <span class="font-semibold text-muted-foreground">{{ key }}:</span> {{ value }}
                 </div>
               </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
