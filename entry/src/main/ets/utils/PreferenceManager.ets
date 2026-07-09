import { UserProfile } from '../models/DataModels'
import { preferences } from '@kit.ArkData'

const PREF_NAME: string = 'shopcompare_data'

let dataPreferences: preferences.Preferences | null = null

async function getPrefs(): Promise<preferences.Preferences> {
  if (dataPreferences !== null) {
    return dataPreferences
  }
  throw new Error('Preferences not initialized. Call PreferenceManager.initPreferences(context) first.')
}

async function persistString(key: string, value: string): Promise<void> {
  if (dataPreferences !== null) {
    dataPreferences.putSync(key, value)
    dataPreferences.flush()
  }
}

async function persistBoolean(key: string, value: boolean): Promise<void> {
  if (dataPreferences !== null) {
    dataPreferences.putSync(key, value)
    dataPreferences.flush()
  }
}

class PreferenceStore {
  private favoriteIds: string[] = []
  private darkMode: boolean = false
  private notificationEnabled: boolean = true
  private userProfile: UserProfile = {
    preferences: [],
    dimensions: [],
    budget: '',
    platforms: [],
    isFirstLaunch: true
  }
  private currentUserId: string = 'u_me'
  private searchHistory: string[] = []

  async loadFromDisk(): Promise<void> {
    if (dataPreferences === null) {
      return
    }
    if (dataPreferences.hasSync('favoriteIds')) {
      let favJson: string = dataPreferences.getSync('favoriteIds', '[]') as string
      this.favoriteIds = JSON.parse(favJson) as string[]
    }
    if (dataPreferences.hasSync('searchHistory')) {
      let histJson: string = dataPreferences.getSync('searchHistory', '[]') as string
      this.searchHistory = JSON.parse(histJson) as string[]
    }
    if (dataPreferences.hasSync('darkMode')) {
      this.darkMode = dataPreferences.getSync('darkMode', false) as boolean
    }
    if (dataPreferences.hasSync('notificationEnabled')) {
      this.notificationEnabled = dataPreferences.getSync('notificationEnabled', true) as boolean
    }
    if (dataPreferences.hasSync('userProfile')) {
      let profileJson: string = dataPreferences.getSync('userProfile', '{}') as string
      this.userProfile = JSON.parse(profileJson) as UserProfile
    }
    if (dataPreferences.hasSync('isFirstLaunch')) {
      this.userProfile.isFirstLaunch = dataPreferences.getSync('isFirstLaunch', true) as boolean
    }
    if (dataPreferences.hasSync('currentUserId')) {
      this.currentUserId = dataPreferences.getSync('currentUserId', 'u_me') as string
    }
  }

  private saveFavorites(): void {
    persistString('favoriteIds', JSON.stringify(this.favoriteIds))
  }

  private saveSearchHistory(): void {
    persistString('searchHistory', JSON.stringify(this.searchHistory))
  }

  private saveProfile(): void {
    persistString('userProfile', JSON.stringify(this.userProfile))
    persistBoolean('isFirstLaunch', this.userProfile.isFirstLaunch)
  }

  getFavoriteIds(): string[] {
    return this.favoriteIds
  }

  addFavorite(id: string): void {
    let idx: number = this.favoriteIds.indexOf(id)
    if (idx < 0) {
      this.favoriteIds.push(id)
      this.saveFavorites()
    }
  }

  removeFavorite(id: string): void {
    let idx: number = this.favoriteIds.indexOf(id)
    if (idx >= 0) {
      this.favoriteIds.splice(idx, 1)
      this.saveFavorites()
    }
  }

  isFavorite(id: string): boolean {
    return this.favoriteIds.indexOf(id) >= 0
  }

  getDarkMode(): boolean {
    return this.darkMode
  }

  setDarkMode(enabled: boolean): void {
    this.darkMode = enabled
    persistBoolean('darkMode', enabled)
  }

  getNotificationEnabled(): boolean {
    return this.notificationEnabled
  }

  setNotificationEnabled(enabled: boolean): void {
    this.notificationEnabled = enabled
    persistBoolean('notificationEnabled', enabled)
  }

  saveUserProfile(profile: UserProfile): void {
    this.userProfile = profile
    this.saveProfile()
  }

  loadUserProfile(): UserProfile {
    return this.userProfile
  }

  setFirstLaunchDone(): void {
    this.userProfile.isFirstLaunch = false
    persistBoolean('isFirstLaunch', false)
  }

  isFirstLaunch(): boolean {
    return this.userProfile.isFirstLaunch
  }

  getCurrentUserId(): string {
    return this.currentUserId
  }

  setCurrentUserId(id: string): void {
    this.currentUserId = id
    persistString('currentUserId', id)
  }

  addSearchKeyword(keyword: string): void {
    if (keyword.length === 0) {
      return
    }
    let idx: number = this.searchHistory.indexOf(keyword)
    if (idx >= 0) {
      this.searchHistory.splice(idx, 1)
    }
    this.searchHistory.unshift(keyword)
    if (this.searchHistory.length > 12) {
      this.searchHistory.splice(12, this.searchHistory.length - 12)
    }
    this.saveSearchHistory()
  }

  getSearchHistory(): string[] {
    return this.searchHistory
  }

  clearSearchHistory(): void {
    this.searchHistory = []
    this.saveSearchHistory()
  }
}

let store: PreferenceStore = new PreferenceStore()

export class NavParams {
  static productId: string = '';
  static categoryId: string = '';
  static categoryName: string = '';
  static selectedBrands: string = '';
  static selectedPriceLabel: string = '';
  static selectedMinPrice: number = 0;
  static selectedMaxPrice: number = 0;
  static selectedOtherLabels: string = '';
  static compareProductIds: string = '';
}

export class PreferenceManager {
  static async initPreferences(context: Context): Promise<void> {
    dataPreferences = await preferences.getPreferences(context, PREF_NAME)
    await store.loadFromDisk()
  }

  static getFavoriteIds(): string[] {
    return store.getFavoriteIds()
  }

  static addFavorite(id: string): void {
    store.addFavorite(id)
  }

  static removeFavorite(id: string): void {
    store.removeFavorite(id)
  }

  static isFavorite(id: string): boolean {
    return store.isFavorite(id)
  }

  static getDarkMode(): boolean {
    return store.getDarkMode()
  }

  static setDarkMode(enabled: boolean): void {
    store.setDarkMode(enabled)
  }

  static getNotificationEnabled(): boolean {
    return store.getNotificationEnabled()
  }

  static setNotificationEnabled(enabled: boolean): void {
    store.setNotificationEnabled(enabled)
  }

  static saveUserProfile(profile: UserProfile): void {
    store.saveUserProfile(profile)
  }

  static loadUserProfile(): UserProfile {
    return store.loadUserProfile()
  }

  static setFirstLaunchDone(): void {
    store.setFirstLaunchDone()
  }

  static isFirstLaunch(): boolean {
    return store.isFirstLaunch()
  }

  static getCurrentUserId(): string {
    return store.getCurrentUserId()
  }

  static setCurrentUserId(id: string): void {
    store.setCurrentUserId(id)
  }

  static addSearchKeyword(keyword: string): void {
    store.addSearchKeyword(keyword)
  }

  static getSearchHistory(): string[] {
    return store.getSearchHistory()
  }

  static clearSearchHistory(): void {
    store.clearSearchHistory()
  }
}
