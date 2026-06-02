import { Injectable, inject, signal, computed, effect } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { toSignal } from '@angular/core/rxjs-interop';
import { catchError, of } from 'rxjs';
import { FeatureFlag, FlagKey } from './feature-flag.model';

@Injectable({ providedIn: 'root' })
export class FeatureFlagService {
  private readonly http = inject(HttpClient);
  private readonly apiUrl = 'http://localhost:8080/api/flags';

  private readonly _flags = signal<FeatureFlag[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  readonly flags = this._flags.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  readonly enabledKeys = computed(() =>
    new Set(this._flags().filter(f => f.enabled).map(f => f.key))
  );

  constructor() {
    this.loadFlags();
    // Sync dark mode to DOM
    effect(() => {
      const darkMode = this.isEnabled('GENERAL_DARK_MODE');
      document.documentElement.setAttribute('data-theme', darkMode ? 'dark' : 'light');
    });
  }

  isEnabled(key: FlagKey | string): boolean {
    return this.enabledKeys().has(key);
  }

  loadFlags(): void {
    this._loading.set(true);
    this.http.get<FeatureFlag[]>(this.apiUrl).pipe(
      catchError(err => {
        this._error.set('Failed to load flags from backend. Using defaults.');
        return of(this.defaultFlags());
      })
    ).subscribe(flags => {
      this._flags.set(flags);
      this._loading.set(false);
    });
  }

  toggleFlag(key: string): void {
    this.http.post<FeatureFlag>(`${this.apiUrl}/${key}/toggle`, {}).pipe(
      catchError(() => {
        // Optimistic local toggle as fallback
        const updated = this._flags().map(f =>
          f.key === key ? { ...f, enabled: !f.enabled } : f
        );
        this._flags.set(updated);
        return of(null);
      })
    ).subscribe(flag => {
      if (flag) {
        const updated = this._flags().map(f => f.key === key ? flag : f);
        this._flags.set(updated);
      }
    });
  }

  private defaultFlags(): FeatureFlag[] {
    return [
      { key: 'GENERAL_DARK_MODE', enabled: true, description: 'Dark mode theme', scope: 'GENERAL' },
      { key: 'GENERAL_NOTIFICATION_CENTER', enabled: false, description: 'Notification bell and panel', scope: 'GENERAL' },
      { key: 'BACKEND_ADVANCED_SEARCH', enabled: true, description: 'Advanced search endpoint', scope: 'BACKEND' },
      { key: 'BACKEND_AI_RECOMMENDATIONS', enabled: false, description: 'AI recommendations', scope: 'BACKEND' },
      { key: 'WEB_NEW_DASHBOARD', enabled: true, description: 'Redesigned dashboard', scope: 'WEB' },
      { key: 'WEB_EXPERIMENTAL_CHARTS', enabled: false, description: 'Experimental charts', scope: 'WEB' },
      { key: 'MOBILE_BIOMETRIC_AUTH', enabled: true, description: 'Biometric auth UI', scope: 'MOBILE' },
      { key: 'MOBILE_OFFLINE_MODE', enabled: false, description: 'Offline mode indicator', scope: 'MOBILE' },
    ];
  }
}
