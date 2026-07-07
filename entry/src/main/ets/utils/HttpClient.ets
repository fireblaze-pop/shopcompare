import { http } from '@kit.NetworkKit'

interface HttpResponse {
  statusCode: number
  data: string
}

interface RequestConfig {
  method: http.RequestMethod
  url: string
  body?: string
  headers?: Record<string, string>
}

const BASE_URL: string = 'http://10.0.2.2:8000/api/v1'
const TIMEOUT: number = 15000

export class HttpClient {
  private baseUrl: string
  private token: string

  constructor(baseUrl: string = BASE_URL) {
    this.baseUrl = baseUrl
    this.token = ''
  }

  setToken(token: string): void {
    this.token = token
  }

  clearToken(): void {
    this.token = ''
  }

  getToken(): string {
    return this.token
  }

  async get(path: string): Promise<HttpResponse> {
    return this.request({ method: http.RequestMethod.GET, url: this.baseUrl + path })
  }

  async post(path: string, body: Object): Promise<HttpResponse> {
    let bodyStr: string = ''
    if (typeof body === 'string') {
      bodyStr = body as string
    } else {
      bodyStr = JSON.stringify(body)
    }
    return this.request({
      method: http.RequestMethod.POST,
      url: this.baseUrl + path,
      body: bodyStr
    })
  }

  async delete(path: string): Promise<HttpResponse> {
    return this.request({ method: http.RequestMethod.DELETE, url: this.baseUrl + path })
  }

  async put(path: string, body: Object): Promise<HttpResponse> {
    return this.request({
      method: http.RequestMethod.PUT,
      url: this.baseUrl + path,
      body: JSON.stringify(body)
    })
  }

  private async request(config: RequestConfig): Promise<HttpResponse> {
    let request = http.createHttp()

    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    }

    if (this.token.length > 0) {
      headers['Authorization'] = 'Bearer ' + this.token
    }

    if (config.headers !== undefined) {
      let keys: string[] = Object.keys(config.headers)
      let i: number = 0
      while (i < keys.length) {
        headers[keys[i]] = config.headers[keys[i]]
        i = i + 1
      }
    }

    try {
      let response = await request.request(
        config.url,
        {
          method: config.method,
          header: headers,
          extraData: config.body !== undefined ? config.body : '',
          connectTimeout: TIMEOUT,
          readTimeout: TIMEOUT
        }
      )

      let dataStr: string = ''
      if (typeof response.result === 'string') {
        dataStr = response.result as string
      } else {
        dataStr = JSON.stringify(response.result)
      }

      request.destroy()

      let result: HttpResponse = {
        statusCode: response.responseCode,
        data: dataStr
      }
      return result
    } catch (err) {
      request.destroy()
      let result: HttpResponse = {
        statusCode: 0,
        data: JSON.stringify({ detail: '网络请求失败' })
      }
      return result
    }
  }
}
