import { Directive, Input, TemplateRef, ViewContainerRef, inject, effect } from '@angular/core';
import { FeatureFlagService } from '../../core/feature-flag.service';

/**
 * Structural directive: renders the host element only when the flag is enabled.
 *
 * Usage:
 *   <div *appFeatureFlag="'WEB_NEW_DASHBOARD'">New dashboard</div>
 *   <div *appFeatureFlag="'WEB_EXPERIMENTAL_CHARTS'; else oldCharts">New</div>
 *   <ng-template #oldCharts>Old charts</ng-template>
 */
@Directive({ selector: '[appFeatureFlag]', standalone: true })
export class FeatureFlagDirective {
  private readonly templateRef = inject(TemplateRef<unknown>);
  private readonly vcr = inject(ViewContainerRef);
  private readonly flagService = inject(FeatureFlagService);

  private flagKey = '';
  private elseTemplateRef: TemplateRef<unknown> | null = null;

  constructor() {
    effect(() => {
      // Re-evaluate whenever flags signal changes
      void this.flagService.flags();
      this.updateView();
    });
  }

  @Input() set appFeatureFlag(key: string) {
    this.flagKey = key;
    this.updateView();
  }

  @Input() set appFeatureFlagElse(templateRef: TemplateRef<unknown>) {
    this.elseTemplateRef = templateRef;
    this.updateView();
  }

  private updateView(): void {
    this.vcr.clear();
    if (this.flagService.isEnabled(this.flagKey)) {
      this.vcr.createEmbeddedView(this.templateRef);
    } else if (this.elseTemplateRef) {
      this.vcr.createEmbeddedView(this.elseTemplateRef);
    }
  }
}
