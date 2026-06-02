import { Injectable, inject, signal, computed, effect } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError, of } from 'rxjs';
import { FeatureFlag, FlagKey } from './feature-flag.model';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class FeatureFlagService {
  private readonly http = inject(HttpClient);
  private readonly backendUrl = `${environment.backendUrl}/api/flags`;

  private readonly _flags = signal<FeatureFlag[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);
  // Which provider is currently active
  private readonly _provider = signal<'backend' | 'unleash'>('backend');

  readonly flags = this._flags.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly provider = this._provider.asReadonly();

  readonly enabledKeys = computed(() =>
    new Set(this._flags().filter(f => f.enabled).map(f => f.key))
  );

  // Unleash client — lazily initialised
  private unleashClient: unknown = null;

  constructor() {
    if (environment.useUnleash) {
      this.initUnleash();
    } else {
      this.loadFromBackend();
    }

    effect(() => {
      const darkMode = this.isEnabled('GENERAL_DARK_MODE');
      document.documentElement.setAttribute('data-theme', darkMode ? 'dark' : 'light');
    });
  }

  isEnabled(key: FlagKey | string): boolean {
    return this.enabledKeys().has(key);
  }

  loadFlags(): void {
    if (environment.useUnleash && this.unleashClient) {
      // Unleash updates itself via SSE/polling — force a manual refresh
      (this.unleashClient as { fetchToggles: () => Promise<void> }).fetchToggles()
        .then(() => this.syncFromUnleash())
        .catch(() => {});
    } else {
      this.loadFromBackend();
    }
  }

  toggleFlag(key: string): void {
    // Toggle always goes through the backend, which calls Unleash Admin API.
    // After the call the Unleash client will pick up the change on next poll.
    this.http.post<FeatureFlag>(`${this.backendUrl}/${key}/toggle`, {}).pipe(
      catchError(() => {
        // Optimistic local toggle on network failure
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

  // ── Unleash provider ──────────────────────────────────────────────────────

  private async initUnleash(): Promise<void> {
    this._loading.set(true);
    try {
      const { UnleashClient } = await import('unleash-proxy-client');
      const { url, clientKey, appName, refreshInterval } = environment.unleash;

      const client = new UnleashClient({ url, clientKey, appName, refreshInterval });

      client.on('ready', () => {
        this.syncFromUnleash();
        this._loading.set(false);
        this._provider.set('unleash');
      });

      client.on('update', () => this.syncFromUnleash());

      client.on('error', (err: unknown) => {
        console.warn('Unleash error, falling back to backend:', err);
        this._error.set('Unleash unreachable — loading from backend.');
        this.loadFromBackend();
      });

      await client.start();
      this.unleashClient = client;
    } catch (err) {
      console.warn('Failed to load Unleash SDK, falling back to backend:', err);
      this._error.set('Unleash SDK failed to load — using backend flags.');
      this.loadFromBackend();
    }
  }

  private syncFromUnleash(): void {
    const client = this.unleashClient as {
      isEnabled: (key: string) => boolean;
    } | null;
    if (!client) return;

    // Preserve scope/description from whatever we already have, update enabled
    const current = this._flags().length
      ? this._flags()
      : this.defaultFlags();

    const updated = current.map(f => ({
      ...f,
      enabled: client.isEnabled(f.key),
    }));
    this._flags.set(updated);
  }

  // ── Backend provider ──────────────────────────────────────────────────────

  private loadFromBackend(): void {
    this._loading.set(true);
    this.http.get<FeatureFlag[]>(this.backendUrl).pipe(
      catchError(() => {
        this._error.set('Failed to load flags from backend. Using hardcoded defaults.');
        return of(this.defaultFlags());
      })
    ).subscribe(flags => {
      this._flags.set(flags);
      this._loading.set(false);
      this._provider.set('backend');
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
