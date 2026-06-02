import { Component, inject, signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { FeatureFlagService } from './core/feature-flag.service';
import { NotificationsComponent } from './features/notifications/notifications.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, NotificationsComponent],
  template: `
    <div class="layout">
      <header class="topbar">
        <div class="topbar-left">
          <span class="logo">🚩 Feature Flags Demo</span>
          <nav class="nav">
            <a routerLink="/dashboard" routerLinkActive="active">Dashboard</a>
            <a routerLink="/flags" routerLinkActive="active">Flag Manager</a>
          </nav>
        </div>
        <div class="topbar-right">
          @if (flagService.isEnabled('GENERAL_NOTIFICATION_CENTER')) {
            <button class="icon-btn" (click)="showNotifs.set(!showNotifs())">
              🔔
              <span class="notif-dot"></span>
            </button>
          }
          <button class="icon-btn" (click)="flagService.toggleFlag('GENERAL_DARK_MODE')" title="Toggle dark mode">
            {{ flagService.isEnabled('GENERAL_DARK_MODE') ? '☀️' : '🌙' }}
          </button>
        </div>
      </header>

      @if (showNotifs() && flagService.isEnabled('GENERAL_NOTIFICATION_CENTER')) {
        <div class="notif-overlay">
          <app-notifications />
        </div>
      }

      <main class="main">
        @if (flagService.loading()) {
          <div class="loading">Loading feature flags...</div>
        } @else {
          <router-outlet />
        }
      </main>
    </div>
  `,
  styles: [`
    .layout { min-height: 100vh; display: flex; flex-direction: column; }
    .topbar {
      display: flex; justify-content: space-between; align-items: center;
      padding: 0 24px; height: 56px;
      background: var(--color-surface); border-bottom: 1px solid var(--color-border);
      position: sticky; top: 0; z-index: 10; box-shadow: var(--shadow);
    }
    .topbar-left { display: flex; align-items: center; gap: 24px; }
    .logo { font-weight: 700; font-size: 16px; }
    .nav { display: flex; gap: 4px; }
    .nav a {
      padding: 6px 12px; border-radius: 6px; text-decoration: none;
      color: var(--color-text-muted); font-size: 14px; font-weight: 500;
      transition: all 0.15s;
    }
    .nav a:hover { background: var(--color-bg); color: var(--color-text); }
    .nav a.active { background: var(--color-bg); color: var(--color-primary); }
    .topbar-right { display: flex; align-items: center; gap: 8px; }
    .icon-btn {
      position: relative; background: none; border: none; cursor: pointer;
      font-size: 18px; padding: 6px; border-radius: 6px;
      transition: background 0.15s;
    }
    .icon-btn:hover { background: var(--color-bg); }
    .notif-dot {
      position: absolute; top: 4px; right: 4px;
      width: 8px; height: 8px; border-radius: 50%; background: #ef4444;
    }
    .notif-overlay {
      position: fixed; top: 64px; right: 16px; z-index: 100;
      box-shadow: 0 10px 25px rgba(0,0,0,0.15);
    }
    .main { flex: 1; padding: 32px 24px; max-width: 1100px; margin: 0 auto; width: 100%; }
    .loading { text-align: center; padding: 48px; color: var(--color-text-muted); }
  `]
})
export class AppComponent {
  readonly flagService = inject(FeatureFlagService);
  readonly showNotifs = signal(false);
}
