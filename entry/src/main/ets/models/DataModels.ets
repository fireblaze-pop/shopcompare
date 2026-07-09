export interface PlatformListing {
  platform: string;
  price: number;
  rating: number;
  reviewCount: number;
  inStock: boolean;
  url: string;
}

export interface ProductSpec {
  key: string;
  value: string;
}

export interface PricePoint {
  date: string;
  price: number;
}

export interface ReviewTag {
  text: string;
  type: number;
  count: number;
}

export interface Product {
  id: string;
  name: string;
  modelCode: string;
  brand: string;
  category: string;
  imageUrl: string;
  specs: ProductSpec[];
  aggregateScore: number;
  aggregateRating: number;
  totalReviewCount: number;
  platformListings: PlatformListing[];
  platformCount: number;
  lowestPrice: number;
  priceSpread: number;
  historicalLow: number;
  priceHistory: PricePoint[];
  reviewTags: ReviewTag[];
  publishDate: string;
  description: string;
}

export interface Category {
  id: string;
  name: string;
  icon: string;
  subCategories: SubCategory[];
}

export interface SubCategory {
  id: string;
  name: string;
}

export interface FilterOption {
  id: string;
  label: string;
  selected: boolean;
}

export interface FilterGroup {
  name: string;
  type: string;
  options: FilterOption[];
}

export interface UserProfile {
  preferences: string[];
  dimensions: string[];
  budget: string;
  platforms: string[];
  isFirstLaunch: boolean;
}

export interface CompareResult {
  products: Product[];
  totalCount: number;
  platformCount: number;
  sortType: string;
}

export interface SearchHistory {
  keyword: string;
  timestamp: number;
}
