import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const body = await readBody(event)
    const { url, method, headers, body: requestBody, name } = body
    const user = await serverSupabaseUser(event)

    if (!user) {
        throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
    }

    const startTime = Date.now()
    let responseData: any = {}
    let responseStatus = 0
    let responseHeaders = {}
    let error = null

    try {
        const response = await fetch(url, {
            method,
            headers: headers || {},
            body: ['GET', 'HEAD'].includes(method) ? undefined : JSON.stringify(requestBody)
        })

        responseStatus = response.status
        responseHeaders = Object.fromEntries(response.headers.entries())

        const contentType = response.headers.get('content-type')
        if (contentType && contentType.includes('application/json')) {
            responseData = await response.json()
        } else {
            responseData = await response.text()
        }

    } catch (e: any) {
        error = e.message
        responseStatus = 500
    }

    const duration = Date.now() - startTime

    // Log to Supabase
    const client = await serverSupabaseClient(event)
    await client.from('logs').insert({
        user_id: user.id,
        type: 'outbound',
        method,
        url,
        status: responseStatus,
        duration_ms: duration
    })

    // Save request if name is provided
    if (name) {
        await client.from('outbound_requests').insert({
            user_id: user.id,
            name,
            url,
            method,
            headers,
            body: requestBody
        })
    }

    return {
        status: responseStatus,
        headers: responseHeaders,
        data: responseData,
        duration,
        error
    }
})
