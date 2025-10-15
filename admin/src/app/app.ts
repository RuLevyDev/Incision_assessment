import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';

import { CatalogItem } from './models/catalog-item.model';
import { ItemStore } from './state/item.store';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.scss',
})
export class App {
  protected readonly store = inject(ItemStore);

  constructor() {
    this.store.initialize();
  }

  protected onSearchChange(event: Event) {
    const value = (event.target as HTMLInputElement).value;
    this.store.setSearch(value);
  }

  protected onCategoryChange(event: Event) {
    const value = (event.target as HTMLSelectElement).value;
    this.store.setCategory(value);
  }

  protected refresh() {
    void this.store.refresh();
  }

  protected selectItem(item: CatalogItem) {
    this.store.selectItem(item.id);
  }

  protected approve(item: CatalogItem) {
    void this.store.approve(item.id);
  }

  protected qualityBadgeClass(band: string): string {
    const normalized = band?.toLowerCase() ?? 'unknown';
    return `quality-badge quality-badge--${normalized}`;
  }

  protected approvalDisabled(item: CatalogItem): boolean {
    return (
      item.score < 90 ||
      item.isApproved ||
      this.store.approvingId() === item.id ||
      this.store.loading()
    );
  }

  protected trackByItemId(_index: number, item: CatalogItem) {
    return item.id;
  }
}
