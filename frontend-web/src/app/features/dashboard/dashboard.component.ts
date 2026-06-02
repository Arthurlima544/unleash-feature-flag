import { Component, inject, computed } from '@angular/core';
import { FeatureFlagService } from '../../core/feature-flag.service';
import { FeatureFlagDirective } from '../../shared/directives/feature-flag.directive';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [FeatureFlagDirective],
  template: `
    <div class="dashboard">
      <h2>Dashboard</h2>
      <p class="subtitle">Angular-specific feature flags are demonstrated here</p>

      <!-- WEB_NEW_DASHBOARD flag -->
      @if (flagService.isEnabled('WEB_NEW_DASHBOARD')) {
        <section class="card new-dashboard">
          <div class="flag-badge badge badge-green">WEB_NEW_DASHBOARD: ON</div>
          <h3>New Dashboard Layout</h3>
          <div class="stats-grid">
            @for (stat of stats(); track stat.label) {
              <div class="stat-card">
                <span class="stat-value">{{ stat.value }}</span>
                <span class="stat-label">{{ stat.label }}</span>
              </div>
            }
          </div>
        </section>
      } @else {
        <section class="card old-dashboard">
          <div class="flag-badge badge badge-red">WEB_NEW_DASHBOARD: OFF</div>
          <h3>Legacy Dashboard</h3>
          <p>This is the old dashboard. Enable <code>WEB_NEW_DASHBOARD</code> to see the new one.</p>
        </section>
      }

      <!-- WEB_EXPERIMENTAL_CHARTS flag (using structural directive) -->
      <section class="card">
        <h3>Analytics Charts</h3>
        <ng-container *appFeatureFlag="'WEB_EXPERIMENTAL_CHARTS'; else basicChart">
          <div class="flag-badge badge badge-green">WEB_EXPERIMENTAL_CHARTS: ON</div>
          <div class="experimental-chart">
            <div class="chart-bar" style="height: 80%"><span>Jan</span></div>
            <div class="chart-bar" style="height: 60%"><span>Feb</span></div>
            <div class="chart-bar" style="height: 90%"><span>Mar</span></div>
            <div class="chart-bar" style="height: 45%"><span>Apr</span></div>
            <div class="chart-bar" style="height: 70%"><span>May</span></div>
          </div>
          <p class="chart-label">Experimental interactive chart (Angular-only feature)</p>
        </ng-container>
        <ng-template #basicChart>
          <div class="flag-badge badge badge-red">WEB_EXPERIMENTAL_CHARTS: OFF</div>
          <p>Basic chart placeholder. Enable <code>WEB_EXPERIMENTAL_CHARTS</code> for interactive charts.</p>
        </ng-template>
      </section>
    </div>
  `,
  styles: [`
    .dashboard { display: flex; flex-direction: column; gap: 24px; }
    .subtitle { color: var(--color-text-muted); margin-top: 4px; margin-bottom: 8px; }
    h3 { margin-bottom: 16px; }
    .flag-badge { margin-bottom: 12px; }
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 16px; }
    .stat-card {
      display: flex; flex-direction: column; align-items: center;
      padding: 16px; background: var(--color-bg); border-radius: var(--radius);
    }
    .stat-value { font-size: 28px; font-weight: 700; color: var(--color-primary); }
    .stat-label { font-size: 12px; color: var(--color-text-muted); text-align: center; }
    .experimental-chart {
      display: flex; align-items: flex-end; gap: 8px;
      height: 120px; padding: 8px; background: var(--color-bg); border-radius: var(--radius);
    }
    .chart-bar {
      flex: 1; background: var(--color-primary); border-radius: 4px 4px 0 0;
      display: flex; align-items: flex-end; justify-content: center;
      padding-bottom: 4px; transition: height 0.3s;
    }
    .chart-bar span { font-size: 11px; color: white; }
    .chart-label { margin-top: 8px; font-size: 13px; color: var(--color-text-muted); }
    code { background: var(--color-bg); padding: 2px 6px; border-radius: 4px; font-size: 13px; }
  `]
})
export class DashboardComponent {
  readonly flagService = inject(FeatureFlagService);

  readonly stats = computed(() => [
    { label: 'Active Users', value: '1,284' },
    { label: 'Flags Active', value: this.flagService.flags().filter(f => f.enabled).length },
    { label: 'Revenue', value: '$48k' },
    { label: 'Uptime', value: '99.9%' },
  ]);
}
