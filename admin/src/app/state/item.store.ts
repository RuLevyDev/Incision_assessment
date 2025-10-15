import { computed, DestroyRef, effect, inject, Injectable, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { CatalogItem } from '../models/catalog-item.model';
import { ItemApiService } from '../services/item-api.service';

@Injectable({ providedIn: 'root' })
export class ItemStore {
  private readonly api = inject(ItemApiService);
  private readonly destroyRef = inject(DestroyRef);

  private readonly itemsSignal = signal<CatalogItem[]>([]);
  private readonly loadingSignal = signal(false);
  private readonly errorSignal = signal<string | null>(null);
  private readonly searchSignal = signal('');
  private readonly categorySignal = signal<'all' | string>('all');
  private readonly selectedIdSignal = signal<string | null>(null);
  private readonly approvingIdSignal = signal<string | null>(null);

  private initialized = false;
  private refreshHandle: ReturnType<typeof setInterval> | null = null;

  readonly items = this.itemsSignal.asReadonly();
  readonly loading = this.loadingSignal.asReadonly();
  readonly error = this.errorSignal.asReadonly();
  readonly search = this.searchSignal.asReadonly();
  readonly category = this.categorySignal.asReadonly();
  readonly selectedId = this.selectedIdSignal.asReadonly();
  readonly approvingId = this.approvingIdSignal.asReadonly();

  readonly categories = computed(() => {
    const set = new Set<string>();
    for (const item of this.itemsSignal()) {
      const category = item.category.trim();
      if (category.length > 0) {
        set.add(category);
      }
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b));
  });

  readonly filteredItems = computed(() => {
    const query = this.searchSignal().trim().toLowerCase();
    const category = this.categorySignal();

    const filtered = this.itemsSignal().filter((item) => {
      const matchesCategory = category === 'all' || item.category === category;
      if (!matchesCategory) {
        return false;
      }

      if (query.length === 0) {
        return true;
      }

      return (
        item.title.toLowerCase().includes(query) ||
        item.description.toLowerCase().includes(query) ||
        item.category.toLowerCase().includes(query) ||
        item.tags.some((tag) => tag.toLowerCase().includes(query))
      );
    });

    return filtered.sort((a, b) => {
      const scoreComparison = b.score - a.score;
      if (scoreComparison !== 0) {
        return scoreComparison;
      }
      return a.title.localeCompare(b.title);
    });
  });

  readonly selectedItem = computed(() => {
    const selectedId = this.selectedIdSignal();
    const items = this.itemsSignal();

    if (items.length === 0) {
      return null;
    }

    if (selectedId) {
      const match = items.find((item) => item.id === selectedId);
      if (match) {
        return match;
      }
    }

    const filtered = this.filteredItems();
    return filtered.length > 0 ? filtered[0] : items[0];
  });

  constructor() {
    effect(
      () => {
        const filtered = this.filteredItems();
        const selectedId = this.selectedIdSignal();

        if (filtered.length === 0) {
          if (selectedId !== null) {
            queueMicrotask(() => this.selectedIdSignal.set(null));
          }
          return;
        }

        if (selectedId === null || !filtered.some((item) => item.id === selectedId)) {
          queueMicrotask(() => this.selectedIdSignal.set(filtered[0].id));
        }
      },
      { allowSignalWrites: true },
    );

    this.destroyRef.onDestroy(() => {
      if (this.refreshHandle) {
        clearInterval(this.refreshHandle);
      }
    });
  }

  initialize() {
    if (this.initialized) {
      return;
    }
    this.initialized = true;
    void this.refresh();
    this.refreshHandle = setInterval(() => {
      void this.refresh({ silent: true });
    }, 5000);
  }

  async refresh(options: { silent?: boolean } = {}) {
    if (!options.silent) {
      this.loadingSignal.set(true);
    }

    try {
      const items = await firstValueFrom(this.api.list());
      this.itemsSignal.set(items);
      this.errorSignal.set(null);

      if (items.length > 0) {
        const selectedId = this.selectedIdSignal();
        if (!selectedId || !items.some((item) => item.id === selectedId)) {
          this.selectedIdSignal.set(items[0].id);
        }
      } else {
        this.selectedIdSignal.set(null);
      }
    } catch (error) {
      this.errorSignal.set(this.describeError(error));
    } finally {
      if (!options.silent) {
        this.loadingSignal.set(false);
      }
    }
  }

  setSearch(value: string) {
    this.searchSignal.set(value);
  }

  setCategory(category: string) {
    this.categorySignal.set(category === 'all' ? 'all' : category);
  }

  selectItem(id: string | null) {
    this.selectedIdSignal.set(id);
  }

  async approveSelected() {
    const item = this.selectedItem();
    if (!item) {
      return;
    }
    await this.approve(item.id);
  }

  async approve(id: string) {
    this.approvingIdSignal.set(id);
    try {
      const approved = await firstValueFrom(this.api.approve(id));
      const items = this.itemsSignal().map((item) => (item.id === approved.id ? approved : item));
      this.itemsSignal.set(items);
      this.errorSignal.set(null);
    } catch (error) {
      this.errorSignal.set(this.describeError(error));
    } finally {
      this.approvingIdSignal.set(null);
    }
  }

  private describeError(error: unknown): string {
    if (typeof error === 'string') {
      return error;
    }

    if (error && typeof error === 'object') {
      const maybeStatus = (error as { status?: number }).status ?? null;
      const maybeError = (error as { error?: unknown }).error ?? null;

      if (maybeStatus === 0) {
        return 'Cannot reach the creator API. Ensure the Flutter app is running.';
      }

      if (maybeError) {
        if (typeof maybeError === 'string') {
          return maybeError;
        }

        if (typeof maybeError === 'object') {
          const errorsRecord = maybeError as Record<string, unknown>;
          const nestedErrors = errorsRecord['errors'];
          if (nestedErrors && typeof nestedErrors === 'object') {
            const messages = Object.values(nestedErrors as Record<string, string>);
            if (messages.length > 0) {
              return messages.join(' ');
            }
          }
          const singleError = errorsRecord['error'];
          if (typeof singleError === 'string') {
            return singleError;
          }
        }
      }
    }
    return 'Unexpected error while communicating with the creator API.';
  }
}
