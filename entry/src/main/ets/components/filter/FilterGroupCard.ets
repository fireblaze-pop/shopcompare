import { FilterGroup, FilterOption } from '../../models/DataModels'
import { FilterOptionChip } from './FilterOptionChip'

function emptyFilterGroup(): FilterGroup {
  return {
    name: '',
    type: '',
    options: []
  }
}

@Component
export struct FilterGroupCard {
  @Prop group: FilterGroup = emptyFilterGroup()
  @Prop selectedIds: string[] = []

  onFilterOptionAction: (
    optionId: string
  ) => void = (
    optionId: string
  ): void => {}

  build() {
    Column() {
      Text(this.group.name)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 14 })

      Flex({
        wrap: FlexWrap.Wrap
      }) {
        ForEach(
          this.group.options,
          (option: FilterOption) => {
            FilterOptionChip({
              label: this.getDisplayLabel(option),
              selected:
                this.selectedIds.indexOf(option.id) >= 0,
              onOptionAction: (): void => {
                this.onFilterOptionAction(option.id)
              }
            })
              .margin({
                right: 10,
                bottom: 10
              })
          },
          (option: FilterOption) => option.id
        )
      }
      .width('100%')
    }
    .width('100%')
    .padding({
      left: 18,
      right: 8,
      top: 18,
      bottom: 8
    })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
  }

  private getDisplayLabel(
    option: FilterOption
  ): string {
    if (this.group.type === 'price') {
      return '¥' + option.label
    }

    return option.label
  }
}
