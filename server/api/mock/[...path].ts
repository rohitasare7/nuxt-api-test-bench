import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const params = event.context.params
    if (!params || !params.path) {
        throw createError({ statusCode: 400, statusMessage: 'Invalid path' })
    }

    // Path format: /api/mock/ACTUAL_PATH
    // params.path will be the full path after /api/mock/
    const actualPath = '/' + (Array.isArray(params.path) ? params.path.join('/') : params.path)
    const method = event.method

    const client = await serverSupabaseClient(event)

    console.log('Mock Handler - Looking for:', { actualPath, method })

    // Find the API definition (no longer filtering by user_id)
    const { data, error } = await client
        .from('inbound_apis')
        .select('*')
        .eq('path', actualPath)
        .eq('method', method)
        .single()

    console.log('Mock Handler - Query result:', { data, error })

    if (error || !data) {
        throw createError({ statusCode: 404, statusMessage: 'API Endpoint Not Found' })
    }

    // Check authentication if auth_token is configured
    if (data.auth_token) {
        const authHeader = getHeader(event, 'authorization')
        if (!authHeader || authHeader !== data.auth_token) {
            throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
        }
    }

    // Log the request
    await client.from('logs').insert({
        user_id: data.user_id,
        type: 'inbound',
        method: method,
        url: actualPath,
        status: data.response_status,
        duration_ms: 0 // Placeholder
    })

    // Set status and return body
    setResponseStatus(event, data.response_status)
    return data.response_body
})
