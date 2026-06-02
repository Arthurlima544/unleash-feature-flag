import { Component, inject } from '@angular/core';
import { FeatureFlagService } from '../../core/feature-flag.service';
import { FeatureFlag, FlagScope } from '../../core/feature-flag.model';

@Component({
  selector: 'app-flag-manager',
  standalone: true,
  template: `
    <div class="flag-manager">
      <div class="header">
        <h2>Feature Flag Manager</h2>
        <div class="header-right">
          <span class="badge" [class]="flagService.provider() === 'unleash' ? 'badge-green' : 'badge-blue'">
            Provider: {{ flagService.provider() === 'unleash' ? '🚩 Unleash' : '⚙️ Backend YAML' }}
          </span>
          @if (flagService.provider() !== 'unleash') {
            <button class="btn btn-outline" (click)="reset()">Reset to Defaults</button>
          }
        </div>
      </div>
      <p class="subtitle">
        Toggle flags below.
        @if (flagService.provider() === 'unleash') {
          Changes are applied directly in Unleash. Open
          <a href="http://localhost:4242" target="_blank">localhost:4242</a>
          to manage from the UI.
        } @else {
          Changes are in-memory on the backend (with local fallback if unreachable).
        }
      </p>

      @if (flagService.error()) {
        <div class="alert">⚠ {{ flagService.error() }}</div>
      }

      @for (scope of scopes; track scope) {
        <section class="scope-section">
          <h3 class="scope-title">
            <span class="scope-badge badge" [class]="scopeBadgeClass(scope)">{{ scope }}</span>
          </h3>
          <div class="flag-grid">
            @for (flag of flagsByScope(scope); track flag.key) {
              <div class="flag-card card">
                <div class="flag-header">
                  <code class="flag-key">{{ flag.key }}</code>
                  <button
                    class="toggle"
                    [class.on]="flag.enabled"
                    (click)="flagService.toggleFlag(flag.key)"
                    [attr.aria-label]="'Toggle ' + flag.key"
                  >
                    <span class="thumb"></span>
                  </button>
                </div>
                <p class="flag-desc">{{ flag.description }}</p>
                <span class="badge" [class]="flag.enabled ? 'badge-green' : 'badge-red'">
                  {{ flag.enabled ? 'ENABLED' : 'DISABLED' }}
                </span>
              </div>
            }
          </div>
        </section>
      }
    </div>
  `,
  styles: [`
    .flag-manager { display: flex; flex-direction: column; gap: 28px; }
    .header { display: flex; justify-content: space-between; align-items: center; }
    .header-right { display: flex; align-items: center; gap: 8px; }
    a { color: var(--color-primary); }
    .subtitle { color: var(--color-text-muted); }
    .alert { background: #fef3c7; border: 1px solid #f59e0b; color: #92400e; padding: 10px 14px; border-radius: var(--radius); }
    .scope-section { display: flex; flex-direction: column; gap: 12px; }
    .scope-title { display: flex; align-items: center; gap: 8px; }
    .scope-badge { font-size: 13px; padding: 3px 10px; }
    .flag-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; }
    .flag-card { display: flex; flex-direction: column; gap: 8px; }
    .flag-header { display: flex; justify-content: space-between; align-items: center; }
    .flag-key { font-size: 12px; background: var(--color-bg); padding: 3px 7px; border-radius: 4px; }
    .flag-desc { font-size: 13px; color: var(--color-text-muted); }

    .toggle {
      position: relative; width: 44px; height: 24px;
      background: var(--color-border); border-radius: 12px; border: none; cursor: pointer;
      transition: background 0.2s; flex-shrink: 0;
    }
    .toggle.on { background: var(--color-primary); }
    .thumb {
      position: absolute; top: 3px; left: 3px;
      width: 18px; height: 18px; border-radius: 50%; background: white;
      transition: transform 0.2s; box-shadow: 0 1px 2px rgba(0,0,0,0.2);
    }
    .toggle.on .thumb { transform: translateX(20px); }
  `]
})
export class FlagManagerComponent {
  readonly flagService = inject(FeatureFlagService);
  readonly scopes: FlagScope[] = ['GENERAL', 'BACKEND', 'WEB', 'MOBILE'];

  flagsByScope(scope: FlagScope): FeatureFlag[] {
    return this.flagService.flags().filter(f => f.scope === scope);
  }

  scopeBadgeClass(scope: FlagScope): string {
    const map: Record<FlagScope, string> = {
      GENERAL: 'badge-blue',
      BACKEND: 'badge-gray',
      WEB: 'badge-green',
      MOBILE: 'badge-red',
    };
    return map[scope];
  }

  reset(): void {
    fetch('http://localhost:8080/api/flags/reset', { method: 'POST' })
      .then(() => this.flagService.loadFlags())
      .catch(() => this.flagService.loadFlags());
  }
}
