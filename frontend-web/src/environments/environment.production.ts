export const environment = {
  production: true,
  backendUrl: '',

  useUnleash: true,

  unleash: {
    url: '/api/frontend', // served via nginx proxy in production
    clientKey: 'default:production.unleash-frontend-token',
    appName: 'frontend-web',
    refreshInterval: 30,
  },
};
