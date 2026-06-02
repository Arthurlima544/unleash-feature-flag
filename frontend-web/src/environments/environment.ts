// Development environment — toggle useUnleash to switch providers
export const environment = {
  production: false,
  backendUrl: 'http://localhost:8080',

  useUnleash: true, // ← flip to false to use the Spring Boot backend flags

  unleash: {
    url: 'http://localhost:4242/api/frontend',
    clientKey: 'default:development.unleash-frontend-token',
    appName: 'frontend-web',
    refreshInterval: 15, // seconds
  },
};
