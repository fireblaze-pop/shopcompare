import { RadarDimension } from '../models/RecommendationModels'

interface LabelPos {
  x: number
  y: number
  text: string
  value: number
}

interface AxisEnd {
  endX: number
  endY: number
}

@Component
export struct RadarChart {
  @Prop dimensions: RadarDimension[] = []
  @Prop chartSize: number = 280

  @State gridLevels: number[][][] = []
  @State dataPoints: number[][] = []
  @State axisEnds: AxisEnd[] = []
  @State labelPositions: LabelPos[] = []
  @State center: number = 140
  @State ready: boolean = false

  aboutToAppear(): void {
    this.calculate()
  }

  private calculate(): void {
    let cx: number = this.chartSize / 2
    let cy: number = this.chartSize / 2
    let R: number = this.chartSize / 2 - 48

    this.center = cx

    let levels: number[] = [
      0.25,
      0.5,
      0.75,
      1.0
    ]

    this.gridLevels = []

    let l: number = 0

    while (l < levels.length) {
      let pts: number[][] = []
      let i: number = 0

      while (i < 6) {
        let angle: number =
          (-90 + i * 60) *
          Math.PI /
          180

        let x: number =
          cx +
          R *
          levels[l] *
          Math.cos(angle)

        let y: number =
          cy +
          R *
          levels[l] *
          Math.sin(angle)

        pts.push([x, y])

        i = i + 1
      }

      this.gridLevels.push(pts)

      l = l + 1
    }

    this.dataPoints = []
    this.axisEnds = []
    this.labelPositions = []

    let d: number = 0

    while (d < 6) {
      let angle: number =
        (-90 + d * 60) *
        Math.PI /
        180

      let cosA: number = Math.cos(angle)
      let sinA: number = Math.sin(angle)

      let ex: number = cx + R * cosA
      let ey: number = cy + R * sinA

      let axis: AxisEnd = {
        endX: ex,
        endY: ey
      }

      this.axisEnds.push(axis)

      let value: number = 50
      let label: string = ''

      if (d < this.dimensions.length) {
        value = this.dimensions[d].value
        label = this.dimensions[d].label
      }

      let dr: number =
        R *
        value /
        100

      let dx: number =
        cx +
        dr *
        cosA

      let dy: number =
        cy +
        dr *
        sinA

      this.dataPoints.push([
        dx,
        dy
      ])

      let labelR: number = R + 30

      let lx: number =
        cx +
        labelR *
        cosA

      let ly: number =
        cy +
        labelR *
        sinA

      let lp: LabelPos = {
        x: lx,
        y: ly,
        text: label,
        value: value
      }

      this.labelPositions.push(lp)

      d = d + 1
    }

    this.ready = true
  }

  build() {
    Column() {
      if (
        this.ready &&
        this.dimensions.length >= 6
      ) {
        Stack() {
          ForEach(
            this.gridLevels,
            (
              pts: number[][],
              index: number
            ) => {
              Polygon({
                width: this.chartSize,
                height: this.chartSize
              })
                .points(pts)
                .fill(
                  index === 0 ?
                  '#FAFAFD' :
                  Color.Transparent
                )
                .stroke(
                  index ===
                  this.gridLevels.length - 1 ?
                  '#D8DAE3' :
                  '#ECEEF3'
                )
                .strokeWidth(
                  index ===
                  this.gridLevels.length - 1 ?
                  0.8 :
                  0.5
                )
            },
            (
              pts: number[][],
              index: number
            ) => index.toString()
          )

          ForEach(
            this.axisEnds,
            (
              axis: AxisEnd,
              index: number
            ) => {
              Line()
                .width(this.chartSize)
                .height(this.chartSize)
                .startPoint([
                  this.center,
                  this.center
                ])
                .endPoint([
                  axis.endX,
                  axis.endY
                ])
                .stroke('#ECEEF3')
                .strokeWidth(0.5)
            },
            (
              axis: AxisEnd,
              index: number
            ) => index.toString()
          )

          Polygon({
            width: this.chartSize,
            height: this.chartSize
          })
            .points(this.dataPoints)
            .fill('#5267E8')
            .fillOpacity(0.20)
            .stroke('#5267E8')
            .strokeWidth(2.2)

          Circle({
            width: 6,
            height: 6
          })
            .position({
              x: this.center - 3,
              y: this.center - 3
            })
            .fill('#AAB3F5')

          ForEach(
            this.dataPoints,
            (
              pt: number[],
              index: number
            ) => {
              Circle({
                width: 9,
                height: 9
              })
                .position({
                  x: pt[0] - 4.5,
                  y: pt[1] - 4.5
                })
                .fill('#5267E8')
                .stroke(Color.White)
                .strokeWidth(2)
            },
            (
              pt: number[],
              index: number
            ) => index.toString()
          )

          ForEach(
            this.labelPositions,
            (
              lp: LabelPos,
              index: number
            ) => {
              Text(
                lp.text +
                '\n' +
                lp.value.toString()
              )
                .fontSize(10)
                .fontColor('#4C4F56')
                .fontWeight(FontWeight.Medium)
                .lineHeight(15)
                .width(72)
                .maxLines(2)
                .textAlign(TextAlign.Center)
                .position({
                  x: lp.x - 36,
                  y: lp.y - 15
                })
            },
            (
              lp: LabelPos,
              index: number
            ) => index.toString()
          )
        }
        .width(this.chartSize)
        .height(this.chartSize)
      }
    }
    .width(this.chartSize)
    .height(this.chartSize)
  }
}
