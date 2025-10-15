export interface CatalogItem {
  id: string;
  title: string;
  description: string;
  category: string;
  tags: string[];
  score: number;
  qualityBand: string;
  isApproved: boolean;
  createdAt: string;
  updatedAt: string;
}
