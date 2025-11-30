<script setup lang="ts">
import { LayoutDashboard, ArrowDownLeft, ArrowUpRight, Activity } from 'lucide-vue-next'

definePageMeta({
  middleware: 'auth'
})

const client = useSupabaseClient()
const user = useSupabaseUser()

const stats = ref({
  inboundCount: 0,
  outboundCount: 0,
  logsCount: 0
})

const recentActivity = ref([])

onMounted(async () => {
  console.log('user.value.id --> '+JSON.stringify(user.value));
  if (!user.value) return

  // Fetch counts
  const { count: inboundCount } = await client.from('inbound_apis').select('*', { count: 'exact', head: true }).eq('user_id', user.value.id ?? user.value.sub)
  const { count: outboundCount } = await client.from('outbound_requests').select('*', { count: 'exact', head: true }).eq('user_id', user.value.id ?? user.value.sub)
  const { count: logsCount } = await client.from('logs').select('*', { count: 'exact', head: true }).eq('user_id', user.value.id ?? user.value.sub)

  stats.value = {
    inboundCount: inboundCount || 0,
    outboundCount: outboundCount || 0,
    logsCount: logsCount || 0
  }

  // Fetch recent logs
  const { data: logs } = await client
    .from('logs')
    .select('*')
    .eq('user_id', user.value.id ?? user.value.sub)
    .order('created_at', { ascending: false })
    .limit(5)
    
  if (logs) recentActivity.value = logs
})
</script>

<template>
  <div class="p-8 space-y-8">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p class="text-muted-foreground mt-1">Overview of your API activities</p>
      </div>
    </div>

    <div class="grid gap-4 md:grid-cols-3">
      <!-- Quick Stats -->
      <div class="p-6 rounded-xl border border-border bg-card text-card-foreground shadow-sm">
        <div class="flex flex-row items-center justify-between space-y-0 pb-2">
          <h3 class="tracking-tight text-sm font-medium">Total Inbound APIs</h3>
          <ArrowDownLeft class="h-4 w-4 text-muted-foreground" />
        </div>
        <div class="text-2xl font-bold">{{ stats.inboundCount }}</div>
      </div>

      <div class="p-6 rounded-xl border border-border bg-card text-card-foreground shadow-sm">
        <div class="flex flex-row items-center justify-between space-y-0 pb-2">
          <h3 class="tracking-tight text-sm font-medium">Total Outbound Requests</h3>
          <ArrowUpRight class="h-4 w-4 text-muted-foreground" />
        </div>
        <div class="text-2xl font-bold">{{ stats.outboundCount }}</div>
      </div>
      
      <div class="p-6 rounded-xl border border-border bg-card text-card-foreground shadow-sm">
        <div class="flex flex-row items-center justify-between space-y-0 pb-2">
          <h3 class="tracking-tight text-sm font-medium">Total Activity Logs</h3>
          <Activity class="h-4 w-4 text-muted-foreground" />
        </div>
        <div class="text-2xl font-bold">{{ stats.logsCount }}</div>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="rounded-xl border border-border bg-card text-card-foreground shadow-sm">
      <div class="p-6 flex flex-col space-y-1.5 border-b border-border">
        <h3 class="font-semibold leading-none tracking-tight">Recent Activity</h3>
        <p class="text-sm text-muted-foreground">Your latest API calls and mocks.</p>
      </div>
      <div class="p-6">
        <div v-if="recentActivity.length === 0" class="flex items-center justify-center py-8 text-muted-foreground text-sm">
          No activity yet. Start by creating an Inbound API or making an Outbound Request.
        </div>
        <div v-else class="space-y-4">
          <div v-for="log in recentActivity" :key="log.id" class="flex items-center justify-between text-sm">
            <div class="flex items-center gap-3">
              <span :class="{
                'px-2 py-0.5 rounded text-xs font-bold uppercase': true,
                'bg-blue-500/10 text-blue-500': log.type === 'inbound',
                'bg-purple-500/10 text-purple-500': log.type === 'outbound',
              }">{{ log.type }}</span>
              <span class="font-mono">{{ log.method }}</span>
              <span class="text-muted-foreground truncate max-w-[300px]">{{ log.url }}</span>
            </div>
            <div class="flex items-center gap-4">
              <span :class="{
                'font-bold': true,
                'text-green-500': log.status >= 200 && log.status < 300,
                'text-yellow-500': log.status >= 300 && log.status < 400,
                'text-red-500': log.status >= 400
              }">{{ log.status }}</span>
              <span class="text-muted-foreground text-xs">{{ new Date(log.created_at).toLocaleTimeString() }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
