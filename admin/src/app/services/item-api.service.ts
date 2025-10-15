import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

import { CatalogItem } from '../models/catalog-item.model';

interface ListOptions {
  search?: string;
  category?: string;
}

@Injectable({ providedIn: 'root' })
export class ItemApiService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = 'http://127.0.0.1:8080';

  list(options: ListOptions = {}): Observable<CatalogItem[]> {
    let params = new HttpParams();
    if (options.search) {
      params = params.set('search', options.search);
    }
    if (options.category && options.category !== 'all') {
      params = params.set('category', options.category);
    }
    return this.http.get<CatalogItem[]>(`${this.baseUrl}/items`, { params });
  }

  getById(id: string): Observable<CatalogItem> {
    return this.http.get<CatalogItem>(`${this.baseUrl}/items/${id}`);
  }

  approve(id: string): Observable<CatalogItem> {
    return this.http.post<CatalogItem>(`${this.baseUrl}/items/${id}/approve`, {});
  }
}
