import { UserProfile, LocalUserInfo } from '../models/DataModels'
import { preferences } from '@kit.ArkData'

const PREF_NAME: string = 'shopcompare_data'

interface LocalUserInfoEntry {
  userId: string
  info: LocalUserInfo
}

interface UserProfileEntry {
  userId: string
  profile: UserProfile
}

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
  private currentUserId: string = 'u_me'
  private searchHistory: string[] = []
  private localUserInfos: LocalUserInfoEntry[] = []
  private userProfiles: UserProfileEntry[] = []

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
    if (dataPreferences.hasSync('currentUserId')) {
      this.currentUserId = dataPreferences.getSync('currentUserId', 'u_me') as string
    }
    if (dataPreferences.hasSync('userProfiles')) {
      let profileListJson: string =
        dataPreferences.getSync(
          'userProfiles',
          '[]'
        ) as string
      this.userProfiles =
        JSON.parse(profileListJson) as UserProfileEntry[]
    } else if (dataPreferences.hasSync('userProfile')) {
      let legacyProfileJson: string =
        dataPreferences.getSync(
          'userProfile',
          '{}'
        ) as string
      let legacyProfile: UserProfile =
        JSON.parse(legacyProfileJson) as UserProfile

      if (dataPreferences.hasSync('isFirstLaunch')) {
        legacyProfile.isFirstLaunch =
          dataPreferences.getSync(
            'isFirstLaunch',
            true
          ) as boolean
      }

      this.userProfiles.push({
        userId: this.currentUserId,
        profile: this.cloneProfile(legacyProfile)
      })
      this.saveUserProfiles()
    }
    if (dataPreferences.hasSync('localUserInfos')) {
      let userInfoJson: string =
        dataPreferences.getSync(
          'localUserInfos',
          '[]'
        ) as string
      this.localUserInfos =
        JSON.parse(userInfoJson) as LocalUserInfoEntry[]
    }
  }

  private saveFavorites(): void {
    persistString('favoriteIds', JSON.stringify(this.favoriteIds))
  }

  private saveSearchHistory(): void {
    persistString('searchHistory', JSON.stringify(this.searchHistory))
  }

  private saveLocalUserInfos(): void {
    persistString(
      'localUserInfos',
      JSON.stringify(this.localUserInfos)
    )
  }

  private saveUserProfiles(): void {
    persistString(
      'userProfiles',
      JSON.stringify(this.userProfiles)
    )
  }

  private getDefaultUserProfile(): UserProfile {
    return {
      preferences: [],
      dimensions: [],
      budget: '',
      platforms: [],
      isFirstLaunch: true
    }
  }

  private cloneProfile(
    profile: UserProfile
  ): UserProfile {
    let preferencesCopy: string[] = []
    let dimensionsCopy: string[] = []
    let platformsCopy: string[] = []
    let i: number = 0

    while (i < profile.preferences.length) {
      preferencesCopy.push(profile.preferences[i])
      i = i + 1
    }

    i = 0
    while (i < profile.dimensions.length) {
      dimensionsCopy.push(profile.dimensions[i])
      i = i + 1
    }

    i = 0
    while (i < profile.platforms.length) {
      platformsCopy.push(profile.platforms[i])
      i = i + 1
    }

    return {
      preferences: preferencesCopy,
      dimensions: dimensionsCopy,
      budget: profile.budget,
      platforms: platformsCopy,
      isFirstLaunch: profile.isFirstLaunch
    }
  }

  private findCurrentProfileIndex(): number {
    let i: number = 0

    while (i < this.userProfiles.length) {
      if (
        this.userProfiles[i].userId ===
        this.currentUserId
      ) {
        return i
      }

      i = i + 1
    }

    return -1
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
    let index: number = this.findCurrentProfileIndex()
    let profileCopy: UserProfile =
      this.cloneProfile(profile)

    if (index >= 0) {
      this.userProfiles[index].profile = profileCopy
    } else {
      this.userProfiles.push({
        userId: this.currentUserId,
        profile: profileCopy
      })
    }

    this.saveUserProfiles()
  }

  loadUserProfile(): UserProfile {
    let index: number = this.findCurrentProfileIndex()

    if (index < 0) {
      return this.getDefaultUserProfile()
    }

    return this.cloneProfile(
      this.userProfiles[index].profile
    )
  }

  setFirstLaunchDone(): void {
    let profile: UserProfile = this.loadUserProfile()
    profile.isFirstLaunch = false
    this.saveUserProfile(profile)
  }

  isFirstLaunch(): boolean {
    return this.loadUserProfile().isFirstLaunch
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

  private getDefaultLocalUserInfo(): LocalUserInfo {
    return {
      nickname: '购物达人',
      bio: '让每一次比价都更聪明'
    }
  }

  getLocalUserInfo(): LocalUserInfo {
    let i: number = 0
    while (i < this.localUserInfos.length) {
      if (this.localUserInfos[i].userId === this.currentUserId) {
        return {
          nickname: this.localUserInfos[i].info.nickname,
          bio: this.localUserInfos[i].info.bio
        }
      }
      i = i + 1
    }
    return this.getDefaultLocalUserInfo()
  }

  saveLocalUserInfo(info: LocalUserInfo): void {
    let i: number = 0
    while (i < this.localUserInfos.length) {
      if (this.localUserInfos[i].userId === this.currentUserId) {
        this.localUserInfos[i].info = {
          nickname: info.nickname,
          bio: info.bio
        }
        this.saveLocalUserInfos()
        return
      }
      i = i + 1
    }

    let entry: LocalUserInfoEntry = {
      userId: this.currentUserId,
      info: {
        nickname: info.nickname,
        bio: info.bio
      }
    }
    this.localUserInfos.push(entry)
    this.saveLocalUserInfos()
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

  static loadLocalUserInfo(): LocalUserInfo {
    return store.getLocalUserInfo()
  }

  static saveLocalUserInfo(info: LocalUserInfo): void {
    store.saveLocalUserInfo(info)
  }
}
