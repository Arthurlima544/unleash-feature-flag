import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent)
  },
  {
    path: 'flags',
    loadComponent: () => import('./features/flag-manager/flag-manager.component').then(m => m.FlagManagerComponent)
  },
  { path: '**', redirectTo: 'dashboard' }
];
