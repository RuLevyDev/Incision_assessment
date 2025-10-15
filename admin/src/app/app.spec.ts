import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';

import { CatalogItem } from './models/catalog-item.model';
import { ItemStore } from './state/item.store';
import { App } from './app';

describe('App', () => {
  const now = new Date().toISOString();
  const items = signal<CatalogItem[]>([
    {
      id: '1',
      title: 'Sample Item',
      description: 'A sample item for testing',
      category: 'Books',
      tags: ['reading'],
      score: 95,
      qualityBand: 'excellent',
      isApproved: false,
      createdAt: now,
      updatedAt: now,
    },
  ]);

  const filtered = signal(items());
  const selectedId = signal<string | null>('1');
  const selectedItem = signal(items()[0]);
  const categories = signal(['Books']);

  const mockStore = {
    initialize: jasmine.createSpy('initialize'),
    setSearch: jasmine.createSpy('setSearch'),
    setCategory: jasmine.createSpy('setCategory'),
    refresh: jasmine.createSpy('refresh'),
    selectItem: jasmine.createSpy('selectItem'),
    approve: jasmine.createSpy('approve'),
    items: items.asReadonly(),
    loading: signal(false).asReadonly(),
    error: signal<string | null>(null).asReadonly(),
    search: signal('').asReadonly(),
    category: signal<'all' | string>('all').asReadonly(),
    filteredItems: filtered.asReadonly(),
    selectedId: selectedId.asReadonly(),
    selectedItem: selectedItem.asReadonly(),
    categories: categories.asReadonly(),
    approvingId: signal<string | null>(null).asReadonly(),
  } satisfies Partial<ItemStore>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
      providers: [{ provide: ItemStore, useValue: mockStore }],
    }).compileComponents();
  });

  it('should create the app and initialise the store', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
    expect(mockStore.initialize).toHaveBeenCalled();
  });

  it('should render the dashboard header', () => {
    const fixture = TestBed.createComponent(App);
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Catalog Admin');
  });

  it('should trigger a refresh when clicking the refresh button', () => {
    const fixture = TestBed.createComponent(App);
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    compiled.querySelector<HTMLButtonElement>('.refresh-button')?.click();
    expect(mockStore.refresh).toHaveBeenCalled();
  });
});
