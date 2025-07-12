<script setup>
import { text } from '@fortawesome/fontawesome-svg-core';
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

// Font configuration
const echarts_font = "Fira Sans";

// Color mapping for different variable groups
const getVariableColor = (variable) => {
  // Define colors for each variable group
  const colors = {
    output: '#1f77b4',      // Blue theme
    capital: '#ff7f0e',     // Orange theme
    consumption: '#2ca02c',  // Green theme
    labor: '#d62728',       // Red theme
    technology: '#9467bd',  // Purple theme
    land: '#8c564b',        // Brown theme
    investment: '#e377c2',  // Pink theme
    default: '#17becf'      // Cyan theme
  };
  
  // Map variables to their respective color groups
  const variableGroups = {
    // Output variables
    'Y': colors.output,
    'y': colors.output,
    'g_Y': colors.output,
    'g_y': colors.output,
    
    // Capital variables
    'K': colors.capital,
    'k': colors.capital,
    'g_K': colors.capital,
    'g_k': colors.capital,
    
    // Consumption variables
    'C': colors.consumption,
    'c': colors.consumption,
    'g_C': colors.consumption,
    'g_c': colors.consumption,
    
    // Labor variables
    'L': colors.labor,
    'l': colors.labor,
    'g_L': colors.labor,
    'g_l': colors.labor,
    
    // Technology/TFP variables
    'A': colors.technology,
    'a': colors.technology,
    'g_A': colors.technology,
    'g_a': colors.technology,
    
    // Land variables
    'X': colors.land,
    'x': colors.land,
    'g_X': colors.land,
    'g_x': colors.land,
    
    // Investment variables
    'I': colors.investment,
    'i': colors.investment,
    'g_I': colors.investment,
    'g_i': colors.investment
  };
  
  return variableGroups[variable] || colors.default;
};

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
        fontFamily: echarts_font 
      },
      axisTick: {
        interval: x_axis_interval,
        alignWithLabel: true
      },
      nameLocation: 'middle',
      nameGap: 25
    },
    axisPointer: {
      link: {
        xAxisIndex: 'all'
      },
    },
    yAxis: {
      type: 'value',
      axisLabel: {
        fontFamily: echarts_font
      }
      // name: yLabel || yVar
    },
    series: [
      {
        data: props.dataTable.map(item => item[yVar]),
        type: 'line',
        name: yLabel || yVar,
        showSymbol: false,
        lineStyle: {
          width: 3,
          color: getVariableColor(yVar)
        },
        itemStyle: {
          color: getVariableColor(yVar)
        }
      }
    ],
    tooltip: {
      trigger: 'axis',
      valueFormatter: (value) => value !== undefined ? value.toFixed(3) : '-' // Format values to 3 decimal places, or show '-' if undefined (e.g. growth rates at first period)
    },
    textStyle: {
      fontFamily: echarts_font
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
      group="all"
    />
  </n-card>
</template>

<style scoped>
.plot-card {
  /* max-width: 600px; */
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
