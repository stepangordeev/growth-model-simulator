<script setup>
import { VueLatex } from 'vatex'
import VChart from "vue-echarts"

// Define props
const props = defineProps({
  variable: {
    type: String,
    required: true
  },
  label: {
    type: String,
    required: true
  },
  latexExpression: {
    type: String,
    required: true
  },
  dataTable: {
    type: Array,
    required: true
  }
})

const x_axis_interval = (index, value) => {
  if (index === 0) return true; // Show period 1
  // For remaining periods, show labels at nice intervals
  const totalPeriods = props.dataTable.length;
  if (totalPeriods > 200) {
    return (index + 1) % 50 === 0; 
  } else if (totalPeriods >= 150) {
    return (index + 1) % 25 === 0;
  } else {
    return (index + 1) % 10 === 0; 
  }
};

function makeEchartsOption(yVar, yLabel = null) {
  return {
    xAxis: {
      type: 'category',
      data: props.dataTable.map(item => item.t),
      name: 'Period',
      boundaryGap: true,
      axisLabel: {
        interval: x_axis_interval,
      },
      axisTick: {
        interval: x_axis_interval,
        alignWithLabel: true
      },
      nameLocation: 'middle',
      nameGap: 25
    },
    yAxis: {
      type: 'value',
      // name: yLabel || yVar
    },
    series: [
      {
        data: props.dataTable.map(item => item[yVar]),
        type: 'line',
        // smooth: true,
        name: yLabel || yVar,
        showSymbol: false
      }
    ],
    tooltip: {
      trigger: 'axis',
      valueFormatter: (value) => value.toFixed(3)
    },
    grid: { // padding
      left: '10%',
      right: '10%',
      top: '2%',
      bottom: '18%'
    },
    // legend: {
      // data: [yLabel || yVar]
    // },
    title: {
      show: false,
      text: `${yLabel || yVar} over Time`
    }
  };
}
</script>

<template>
  <n-card class="plot-card" header-style="padding: 0;">
    <template #header>
      <vue-latex :expression="props.latexExpression" display-mode />
    </template>
    <v-chart
      :option="makeEchartsOption(props.variable, props.label)"
      class="echart"
    />
  </n-card>
</template>

<style scoped>
.plot-card {
  max-width: 600px;
  min-height: 300px;
  height: auto;
}

.plot-card :deep(.n-card__content) {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: 0;
}

.plot-card :deep(.n-card-header__main) {
  text-align: center;
  width: 100%;
}

.echart {
  flex: 1;
  min-height: 300px;
  height: auto;
}
</style>
