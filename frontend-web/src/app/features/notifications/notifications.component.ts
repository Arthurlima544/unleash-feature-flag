import { Component, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError, of } from 'rxjs';
import { FeatureFlagService } from '../../core/feature-flag.service';

interface Notification {
  id: number;
  message: string;
  read: boolean;
}

@Component({
  selector: 'app-notifications',
  standalone: true,
  template: `
    @if (flagService.isEnabled('GENERAL_NOTIFICATION_CENTER')) {
      <div class="notification-panel card">
        <div class="panel-header">
          <h3>Notifications</h3>
          <span class="badge badge-green">GENERAL_NOTIFICATION_CENTER: ON</span>
        </div>
        @if (loading()) {
          <p>Loading notifications...</p>
        } @else if (notifications().length === 0) {
          <p class="empty">No notifications</p>
        } @else {
          <ul class="notif-list">
            @for (n of notifications(); track n.id) {
              <li [class.read]="n.read">
                <span class="dot"></span>
                {{ n.message }}
              </li>
            }
          </ul>
        }
      </div>
    }
  `,
  styles: [`
    .notification-panel { min-width: 280px; }
    .panel-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
    .notif-list { list-style: none; display: flex; flex-direction: column; gap: 8px; }
    li { display: flex; align-items: center; gap: 8px; padding: 8px; border-radius: 6px; background: var(--color-bg); }
    li.read { opacity: 0.5; }
    .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--color-primary); flex-shrink: 0; }
    li.read .dot { background: var(--color-text-muted); }
    .empty { color: var(--color-text-muted); }
  `]
})
export class NotificationsComponent {
  readonly flagService = inject(FeatureFlagService);
  private readonly http = inject(HttpClient);

  readonly loading = signal(false);
  readonly notifications = signal<Notification[]>([]);

  constructor() {
    if (this.flagService.isEnabled('GENERAL_NOTIFICATION_CENTER')) {
      this.fetchNotifications();
    }
  }

  private fetchNotifications(): void {
    this.loading.set(true);
    this.http.get<{ notifications: Notification[] }>('http://localhost:8080/api/demo/notifications').pipe(
      catchError(() => of({ notifications: [] }))
    ).subscribe(res => {
      this.notifications.set(res.notifications);
      this.loading.set(false);
    });
  }
}
