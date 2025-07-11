<script setup>
import { defineComponent, ref, computed } from "vue";
import { VueLatex } from 'vatex'
import { use } from "echarts/core";
import { CanvasRenderer } from "echarts/renderers";
import { PieChart, LineChart } from "echarts/charts";
import {
  TitleComponent,
  TooltipComponent,
  GridComponent,
  LegendComponent
} from "echarts/components";
import VChart, { THEME_KEY } from "vue-echarts";
use([
  CanvasRenderer,
  LineChart,
  PieChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
]);

const L_1 = ref(1);
const K_1 = ref(1);
const A_1 = ref(1);
const alpha = ref(0.3);
const beta = ref(0);
const gamma = ref(1);
const delta = ref(0.1);
const phi = ref(0);
const theta = ref(0);
const b0 = ref(0);
const d0 = ref(0);
const d1 = ref(0);
const z = ref(0);
const s = ref(0.3);
const a = ref(0);
const X = ref(1);
const T = ref(50);

// creates marks for naive ui's slider: marks at step intervals, with labels only at min and max
function createLabeledMarks(min, max, step) {
  const count = Math.round((max - min) / step);
  return Object.fromEntries(
    Array.from({ length: count + 1 }, (_, i) => {
      const val = +(min + i * step).toFixed(10);
      let label;
      if (i === 0) {
        label = String(min);
      } else if (i === count) {
        label = String(max);
      } else {
        label = "";
      }
      return [val, label];
    })
  );
}

// Example usage:
const marks_labeled2 = createLabeledMarks(0, 100, 0.1);



const data_table_columns = [
    {
      title: "Period",
      key: "t"
    },
    {
      title: "Y",
      key: "Y"
    },
    {
      title: "K",
      key: "K"
    }
  ]

const Y = (A, K, X, L, gamma, alpha, beta) => {
  return Math.pow(A, gamma) * Math.pow(K, alpha) * Math.pow(X, beta) * Math.pow(L, 1 - alpha - beta);
};

const I_y = (Y, s) => {
  return s * Y;
};

const I_a = (A, K, L_a, z, phi, theta) => {
  return z * Math.pow(A, phi) * Math.pow(K, theta) * Math.pow(L_a, 1 - theta);
};

const A_lom = (A, I_a) => {
  return A + I_a;
};

const L_lom = (L_prev, b0, d0, d1, y) => {
  return L_prev * (1 + b0 - d0 + d1 * y);
};

const K_lom = (K, I_y, delta) => {
  return K * (1 - delta) + I_y;
};

// Simulation function converted from R
const simulate = (
  L_1 = 1,
  K_1 = 1,
  A_1 = 1,
  alpha = 0,
  beta = 0,
  gamma = 1,
  delta = 0,
  phi = 0,
  theta = 0,
  b0 = 0,
  d0 = 0,
  d1 = 0,
  z = 0,
  s = 0,
  a = 0, // researcher share
  X = 1,
  T = 20
) => {
  // Initialize arrays for all variables
  const period = Array.from({ length: T }, (_, i) => i + 1);
  const Y_arr = new Array(T);
  const A_arr = new Array(T);
  const K_arr = new Array(T);
  const L_arr = new Array(T);
  const I_y_arr = new Array(T);
  const I_a_arr = new Array(T);
  const C_arr = new Array(T);
  const y_arr = new Array(T);
  const k_arr = new Array(T);
  const x_arr = new Array(T);
  const c_arr = new Array(T);
  const g_Y = new Array(T);
  const g_y = new Array(T);
  const g_A = new Array(T);
  const g_K = new Array(T);
  const g_k = new Array(T);
  const g_L = new Array(T);
  const g_C = new Array(T);
  const g_c = new Array(T);

  // Initialize first period
  L_arr[0] = L_1;
  K_arr[0] = K_1;
  A_arr[0] = A_1;
  Y_arr[0] = Y(A_arr[0], K_arr[0], X, L_arr[0] * (1 - a), gamma, alpha, beta);
  I_y_arr[0] = I_y(Y_arr[0], s);
  I_a_arr[0] = I_a(A_arr[0], K_arr[0], L_arr[0] * a, z, phi, theta);
  C_arr[0] = Y_arr[0] - I_y_arr[0];
  y_arr[0] = Y_arr[0] / L_arr[0];
  k_arr[0] = K_arr[0] / L_arr[0];
  x_arr[0] = X / L_arr[0];
  c_arr[0] = C_arr[0] / L_arr[0];

  // Simulate forward
  for (let t = 0; t < T - 1; t++) {
    A_arr[t + 1] = A_lom(A_arr[t], I_a_arr[t]);
    L_arr[t + 1] = L_lom(L_arr[t], b0, d0, d1, y_arr[t]);
    K_arr[t + 1] = K_lom(K_arr[t], I_y_arr[t], delta);
    Y_arr[t + 1] = Y(A_arr[t + 1], K_arr[t + 1], X, L_arr[t + 1] * (1 - a), gamma, alpha, beta);
    I_y_arr[t + 1] = I_y(Y_arr[t + 1], s);
    I_a_arr[t + 1] = I_a(A_arr[t + 1], K_arr[t + 1], L_arr[t + 1] * a, z, phi, theta);
    C_arr[t + 1] = Y_arr[t + 1] - I_y_arr[t + 1];
    c_arr[t + 1] = C_arr[t + 1] / L_arr[t + 1];
    y_arr[t + 1] = Y_arr[t + 1] / L_arr[t + 1];
    k_arr[t + 1] = K_arr[t + 1] / L_arr[t + 1];
    x_arr[t + 1] = X / L_arr[t + 1];
    
    // Growth rates (undefined for first period)
    g_Y[t + 1] = (Y_arr[t + 1] - Y_arr[t]) / Y_arr[t];
    g_A[t + 1] = (A_arr[t + 1] - A_arr[t]) / A_arr[t];
    g_K[t + 1] = (K_arr[t + 1] - K_arr[t]) / K_arr[t];
    g_L[t + 1] = (L_arr[t + 1] - L_arr[t]) / L_arr[t];
    g_y[t + 1] = (y_arr[t + 1] - y_arr[t]) / y_arr[t];
    g_k[t + 1] = (k_arr[t + 1] - k_arr[t]) / k_arr[t];
    g_C[t + 1] = (C_arr[t + 1] - C_arr[t]) / C_arr[t];
    g_c[t + 1] = (c_arr[t + 1] - c_arr[t]) / c_arr[t];
  }

  // Return data in the same format as your data_table
  return Array.from({ length: T }, (_, i) => ({
    t: period[i],
    Y: Y_arr[i],
    A: A_arr[i],
    K: K_arr[i],
    L: L_arr[i],
    I_y: I_y_arr[i],
    I_a: I_a_arr[i],
    C: C_arr[i],
    y: y_arr[i],
    k: k_arr[i],
    x: x_arr[i],
    c: c_arr[i],
    g_Y: g_Y[i],
    g_y: g_y[i],
    g_A: g_A[i],
    g_K: g_K[i],
    g_k: g_k[i],
    g_L: g_L[i],
    g_C: g_C[i],
    g_c: g_c[i]
  }));
};

// data table for Naive UI Data Table - now using the simulation
const data_table = computed(() => simulate(
  L_1.value, // L_1
  K_1.value, // K_1
  A_1.value, // A_1
  alpha.value, // alpha
  beta.value, // beta
  gamma.value, // gamma
  delta.value, // delta
  phi.value, // phi
  theta.value, // theta
  b0.value, // b0
  d0.value, // d0
  d1.value, // d1
  z.value, // z
  s.value, // s
  a.value, // a (researcher share)
  X.value, // X
  T.value // T
));

const x_axis_interval = (index, value) => {
  if (index === 0) return true; // Show period 1
  // For remaining periods, show labels at nice intervals
  const totalPeriods = data_table.value.length;
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
      data: data_table.value.map(item => item.t),
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
        data: data_table.value.map(item => item[yVar]),
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
  <n-layout has-sider>

    <n-layout-sider content-style="padding: 24px;">

      <n-divider>Parameters</n-divider>
      <n-collapse>
        <n-collapse-item title="Production Function">
          <n-slider
            v-model:value="alpha" :marks="createLabeledMarks(0, 1, 0.1)" max="1"
            step="mark" show-tooltip="true" placement="bottom"
          >
            <template #thumb>
              <n-icon-wrapper :size="24" :border-radius="12">
                <vue-latex :expression="'\\alpha'" display-mode />
              </n-icon-wrapper>
            </template>
          </n-slider>
        </n-collapse-item>
        <n-collapse-item title="Capital Dynamics">
        </n-collapse-item>
        <n-collapse-item title="Simulation Settings">
          <n-slider
            v-model:value="T" :marks="createLabeledMarks(50, 500, 50)" max="500"
            step="mark" show-tooltip="true" placement="bottom"
          >
            <template #thumb>
              <n-icon-wrapper :size="24" :border-radius="12">
                <vue-latex :expression="'T'" display-mode />
              </n-icon-wrapper>
            </template>
          </n-slider>
        </n-collapse-item>
      </n-collapse>
    </n-layout-sider>
    <n-tabs type="line" animated>
      <n-tab-pane name="aggregates" tab="Aggregates">
        <n-flex>
          <n-card class="plot-card" header-style="padding: 0;">
            <template #header>
              <vue-latex :expression="'Y'" display-mode />
            </template>
            <v-chart
              :option="makeEchartsOption('Y', 'Output (Y)')"
              class="echart"
            />
          </n-card>
          <n-card class="plot-card" header-style="padding: 0;">
            <template #header>
              <vue-latex :expression="'K'" display-mode />
            </template>
            <v-chart
              :option="makeEchartsOption('K', 'Capital (K)')"
              class="echart"
            />
          </n-card>
        </n-flex>
      </n-tab-pane>
      <n-tab-pane name="per_capita" tab="Per Capita">
        
      </n-tab-pane>
      <n-tab-pane name="growth_aggr" tab="Growth: Aggregates">
        
      </n-tab-pane>
      <n-tab-pane name="growth_per_capita" tab="Growth: Per Capita">
        
      </n-tab-pane>
      <n-tab-pane name="table" tab="Table">
        <n-card>
          <n-data-table
            :columns="data_table_columns"
            :data="data_table"
            :bordered="false"
            :max-height="400"
            virtual-scroll
          />
        </n-card>
      </n-tab-pane>
    </n-tabs>
    
  </n-layout>
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
