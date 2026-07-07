export function formatPrice(price: number): string {
  let priceStr: string = price.toFixed(0)
  let result: string = ''
  let count: number = 0
  let i: number = priceStr.length - 1
  while (i >= 0) {
    result = priceStr.charAt(i) + result
    count = count + 1
    if (count === 3 && i > 0) {
      result = ',' + result
      count = 0
    }
    i = i - 1
  }
  return '\u00A5' + result
}

export function formatPriceBrief(price: number): string {
  return '\u00A5' + price.toFixed(0)
}
