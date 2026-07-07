import { PricePoint } from '../models/DataModels'

@Component
export struct PriceChart {
  @Prop priceHistory: PricePoint[] = []
  @Prop chartWidth: number = 360
  @Prop chartHeight: number = 160
  @State private pointCoords: PointCoord[] = []
  @State private lineSegments: LineSegment[] = []
  @State private chartReady: boolean = false

  aboutToAppear(): void {
    this.calculateChart()
  }

  build() {
    Column() {
      if (this.chartReady && this.pointCoords.length > 0) {
        Stack() {
          ForEach(this.lineSegments, (seg: LineSegment, index: number) => {
            Line()
              .width(seg.x2 - seg.x1)
              .height(1)
              .position({ x: seg.x1, y: seg.y1 })
              .backgroundColor('#007AFF')
              .rotate({
                angle: Math.atan2(seg.y2 - seg.y1, seg.x2 - seg.x1) * 180 / Math.PI
              })
          }, (seg: LineSegment, index: number) => index.toString())

          ForEach(this.pointCoords, (pt: PointCoord, index: number) => {
            Circle({ width: 6, height: 6 })
              .position({ x: pt.x - 3, y: pt.y - 3 })
              .fill(pt.isLowest ? '#FF3B30' : '#007AFF')
          }, (pt: PointCoord, index: number) => index.toString())
        }
        .width(this.chartWidth)
        .height(this.chartHeight)
      }
    }
    .width(this.chartWidth)
    .height(this.chartHeight)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
    .padding({ top: 12, right: 12, bottom: 12, left: 12 })
  }

  private calculateChart(): void {
    if (this.priceHistory.length === 0) {
      return
    }
    const points: PricePoint[] = this.priceHistory
    const count: number = points.length
    const paddingH: number = 16
    const paddingV: number = 20
    const chartW: number = this.chartWidth - paddingH * 2
    const chartH: number = this.chartHeight - paddingV * 2

    let min: number = points[0].price
    let max: number = points[0].price
    let lowIdx: number = 0

    for (let i: number = 0; i < count; i++) {
      if (points[i].price < min) {
        min = points[i].price
        lowIdx = i
      }
      if (points[i].price > max) {
        max = points[i].price
      }
    }

    const range: number = max - min
    const scale: number = range > 0 ? chartH / range : 1

    const coords: PointCoord[] = []
    const segments: LineSegment[] = []

    for (let i: number = 0; i < count; i++) {
      const x: number = paddingH + (count > 1 ? (i / (count - 1)) * chartW : chartW / 2)
      const y: number = paddingV + chartH - (points[i].price - min) * scale
      const coord: PointCoord = {
        x: x,
        y: y,
        isLowest: i === lowIdx
      }
      coords.push(coord)

      if (i > 0) {
        const prev: PointCoord = coords[i - 1]
        const seg: LineSegment = {
          x1: prev.x,
          y1: prev.y,
          x2: x,
          y2: y
        }
        segments.push(seg)
      }
    }

    this.pointCoords = coords
    this.lineSegments = segments
    this.chartReady = true
  }
}

interface PointCoord {
  x: number
  y: number
  isLowest: boolean
}

interface LineSegment {
  x1: number
  y1: number
  x2: number
  y2: number
}
