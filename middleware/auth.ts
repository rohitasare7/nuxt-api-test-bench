export default defineNuxtRouteMiddleware((to) => {
    const user = useSupabaseUser()

    console.log('Auth Middleware:', to.path, 'User:', user.value?.email)

    // Temporarily disabled for guest access
    // if (!user.value && to.path !== '/login') {
    //     console.log('Redirecting to login')
    //     return navigateTo('/login')
    // }
})
