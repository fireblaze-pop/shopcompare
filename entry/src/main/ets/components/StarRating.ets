@Component
export struct StarRating {
  @Prop rating: number = 0
  @Prop starIconSize: number = 14
  @Prop showScore: boolean = false
  @Prop reviewCount: number = 0

  build() {
    Row() {
      Text(this.getStarDisplay(1))
        .fontSize(this.starIconSize)
        .fontColor(this.getStarColor(1))
        .opacity(this.getStarOpacity(1))
      Text(this.getStarDisplay(2))
        .fontSize(this.starIconSize)
        .fontColor(this.getStarColor(2))
        .opacity(this.getStarOpacity(2))
      Text(this.getStarDisplay(3))
        .fontSize(this.starIconSize)
        .fontColor(this.getStarColor(3))
        .opacity(this.getStarOpacity(3))
      Text(this.getStarDisplay(4))
        .fontSize(this.starIconSize)
        .fontColor(this.getStarColor(4))
        .opacity(this.getStarOpacity(4))
      Text(this.getStarDisplay(5))
        .fontSize(this.starIconSize)
        .fontColor(this.getStarColor(5))
        .opacity(this.getStarOpacity(5))

      if (this.showScore) {
        Text(this.rating.toFixed(1))
          .fontSize(this.starIconSize * 0.86)
          .fontColor('#1C1C1E')
          .fontWeight(FontWeight.Medium)
          .margin({ left: 6 })

        Text('(' + this.reviewCount.toString() + ')')
          .fontSize(this.starIconSize * 0.72)
          .fontColor('#8E8E93')
          .margin({ left: 2 })
      }
    }
    .alignItems(VerticalAlign.Center)
  }

  private getStarDisplay(position: number): string {
    let fullCount: number = Math.floor(this.rating)
    let hasHalf: boolean = (this.rating - fullCount) >= 0.25
    if (position <= fullCount) {
      return '\u2605'
    }
    if (position === fullCount + 1 && hasHalf) {
      return '\u2605'
    }
    return '\u2606'
  }

  private getStarColor(position: number): string {
    let fullCount: number = Math.floor(this.rating)
    let hasHalf: boolean = (this.rating - fullCount) >= 0.25
    if (position <= fullCount) {
      return '#FFB800'
    }
    if (position === fullCount + 1 && hasHalf) {
      return '#FFB800'
    }
    return '#E5E5EA'
  }

  private getStarOpacity(position: number): number {
    let fullCount: number = Math.floor(this.rating)
    let hasHalf: boolean = (this.rating - fullCount) >= 0.25
    if (position === fullCount + 1 && hasHalf) {
      return 0.5
    }
    return 1.0
  }
}
