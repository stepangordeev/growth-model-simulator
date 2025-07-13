<script setup>
import { defineComponent, ref, computed, h } from "vue";
import { VueLatex } from 'vatex'
import { use } from "echarts/core";
import { CanvasRenderer } from "echarts/renderers";
import { PieChart, LineChart } from "echarts/charts";
import {
  TitleComponent,
  TooltipComponent,
  GridComponent,
  LegendComponent,
  AxisPointerComponent
} from "echarts/components";
import VChart, { THEME_KEY } from "vue-echarts";
use([
  CanvasRenderer,
  LineChart,
  PieChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  AxisPointerComponent
]);
import ParameterSlider from './ParameterSlider.vue'
import VariablePlot from './VariablePlot.vue'
import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon, FontAwesomeLayers } from '@fortawesome/vue-fontawesome'
import { faArrowTrendUp, faHammer, faIndustry, faBabyCarriage, faFlask, faGlobe, faPerson, faRocket, faStar, faTable, faGamepad } from '@fortawesome/free-solid-svg-icons'
import { connect } from "echarts";
/* add icons to the library */
library.add(faArrowTrendUp, faHammer, faIndustry, faBabyCarriage, faFlask, faGlobe, faPerson, faRocket, faStar, faTable, faGamepad)

// fonts
// sans. If change it, also update echarts_font in VariablePlot.vue
import 'vfonts/Inter.css'
// monospace
import 'vfonts/FiraCode.css'

import { NConfigProvider } from 'naive-ui'

  /**
   * Use this for type hints under js file
   * @type import('naive-ui').GlobalThemeOverrides
   */
  const themeOverrides = {
    common: {
      // primaryColor: '#FFBA18'
      primaryColor: '#f99a07'
    },
    Collapse: {
      titleFontSize: '15px'
    },
    Tabs: {
      tabFontSizeMedium: '14px'
    }
  }


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
const T = ref(100);


// creates marks for naive ui's slider: marks at step intervals, with labels only at min and max, plus current value
function createLabeledMarks(min, max, step, currentValue = null) {
  const count = Math.round((max - min) / step);
  const marks = {};
  
  // Determine decimal places based on step size
  const getDecimalPlaces = (stepSize) => {
    if (stepSize >= 1) return 0; // Integer steps
    const stepStr = stepSize.toString();
    if (stepStr.includes('.')) {
      return stepStr.split('.')[1].length;
    }
    return 0;
  };
  
  const decimalPlaces = getDecimalPlaces(step);
  
  // Add marks for each step
  for (let i = 0; i <= count; i++) {
    const val = +(min + i * step).toFixed(10);
    let label = "";
    
    // Label min and max with special handling for 0 and 1 (don't display decimal places)
    if (i === 0) {
      label = min === 0 ? "0" : min.toFixed(decimalPlaces);
    } else if (i === count) {
      label = max === 1 ? "1" : max.toFixed(decimalPlaces);
    }
    
    marks[val] = label;
  }
  
  // Add current value if provided and not already included
  if (currentValue !== null && currentValue >= min && currentValue <= max) {
    const roundedValue = +currentValue.toFixed(10);
    // Apply same special handling of 0 and 1 for current value
    let currentLabel;
    if (currentValue === 0) {
      currentLabel = "0";
    } else if (currentValue === 1) {
      currentLabel = "1";
    } else {
      currentLabel = currentValue.toFixed(decimalPlaces);
    }
    marks[roundedValue] = currentLabel;
  }
  
  return marks;
}

const data_table_columns = computed(() => {
  if (data_table.value.length === 0) return [];
  
  // Get all keys from the first row to create columns dynamically
  const keys = Object.keys(data_table.value[0]);
  
  return keys.map(key => ({
    title: () => h(VueLatex, { expression: key }),
    key: key,
    fixed: key === 't' ? 'left' : undefined,
    render: (row) => {
      const value = row[key];
      if (typeof value === 'number') {
        // If it's an integer or close to an integer, show without decimals
        if (Number.isInteger(value) || Math.abs(value - Math.round(value)) < 0.001) {
          return Math.round(value).toString();
        }
        // Otherwise, round to 3 decimal places
        return value.toFixed(3);
      }
      return value;
    }
  }));
});

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

const model_chosen = ref("Solow");
const models = [
  {
    value: "Solow",
    label: "Solow"
  },
  {
    value: "Malthus",
    label: "Malthus"
  },
  {
    value: "Romer",
    label: "Romer"
  },
  {
    value: "Jones",
    label: "Jones"
  },
  {
    value: "General",
    label: "General"
  }
]

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

// connect all echarts plots together, so that the tooltip is synced (group = "all" needs to be set for each plot)
connect("all")

</script>

<template>
  <n-config-provider :theme-overrides="themeOverrides">

  <n-layout style="min-height: 100vh;">

    <n-layout-header style="height: 64px; padding:24px" bordered>

      <n-flex justify="space-between">

        <n-gradient-text type="primary" size="24">
            Growth Model Simulator
        </n-gradient-text>

        <n-button quaternary type="default" tag="a" href="https://sgordeev.com">
          Stepan Gordeev
        </n-button>

        </n-flex>

    </n-layout-header>

    <n-layout has-sider>

      <n-layout-sider content-style="padding: 24px;" bordered>

        <n-h3 style="text-align: center;">Parameters</n-h3>

        <n-collapse>

          <n-collapse-item title="Production Function">
            <template #header-extra>
              <FontAwesomeIcon icon="hammer" />
            </template>
            <ParameterSlider v-model="alpha" :min="0" :max="1" :step="0.1" latex-expression="\alpha" title="capital share" />
            <ParameterSlider v-model="beta" :min="0" :max="1" :step="0.1" latex-expression="\beta" title="land share" />
            <ParameterSlider v-model="gamma" :min="0" :max="1" :step="0.1" latex-expression="\gamma" title="TFP returns to scale" />
          </n-collapse-item>
          
          <n-collapse-item title="Capital Dynamics">
            <template #header-extra>
              <FontAwesomeIcon icon="industry" />
            </template>
            <ParameterSlider v-model="delta" :min="0" :max="1" :step="0.1" latex-expression="\delta" title="depreciation rate" />
            <ParameterSlider v-model="s" :min="0" :max="1" :step="0.1" latex-expression="s" title="savings rate" />
          </n-collapse-item>
          
          <n-collapse-item title="Population Dynamics">
            <template #header-extra>
              <FontAwesomeIcon icon="baby-carriage" />
            </template>
            <ParameterSlider v-model="b0" :min="0" :max="1" :step="0.1" latex-expression="b_0" title="birth rate" />
            <ParameterSlider v-model="d0" :min="0" :max="1" :step="0.1" latex-expression="d_0" title="death rate intercept" />
            <ParameterSlider v-model="d1" :min="0" :max="1" :step="0.1" latex-expression="d_1" title="death rate decline with income" />
          </n-collapse-item>
          
          <n-collapse-item title="Research Dynamics">
            <template #header-extra>
              <FontAwesomeIcon icon="flask" />
            </template>
            <ParameterSlider v-model="z" :min="0" :max="10" :step="1" latex-expression="z" title="research productivity" />
            <ParameterSlider v-model="phi" :min="0" :max="1" :step="0.1" latex-expression="\phi" title="research returns to scale" />
            <ParameterSlider v-model="theta" :min="0" :max="1" :step="0.1" latex-expression="\theta" title="research automation" />
            <ParameterSlider v-model="a" :min="0" :max="1" :step="0.1" latex-expression="a" title="researcher share" />
          </n-collapse-item>
          
          <n-collapse-item title="Initial Values">
            <template #header-extra>
              <FontAwesomeIcon icon="rocket" />
            </template>
            <ParameterSlider v-model="K_1" :min="1" :max="10" :step="1" latex-expression="K_1" title="initial capital" />
            <ParameterSlider v-model="L_1" :min="1" :max="10" :step="1" latex-expression="L_1" title="initial population" />
            <ParameterSlider v-model="A_1" :min="1" :max="10" :step="1" latex-expression="A_1" title="initial TFP" />
            <ParameterSlider v-model="X" :min="1" :max="10" :step="1" latex-expression="X" title="permanent land" />
          </n-collapse-item>

          <n-collapse-item title="Simulation Settings">
            <template #header-extra>
              <FontAwesomeIcon icon="gamepad" />
            </template>
            <ParameterSlider v-model="T" :min="50" :max="500" :step="50" latex-expression="T" title="time periods" />
          </n-collapse-item>

        </n-collapse>
      </n-layout-sider>

      <n-layout content-style="padding: 0px 24px;">
      
      <n-tabs type="line" animated>
        
        <n-tab-pane name="model">
          <template #tab>
              <FontAwesomeIcon icon="star" />
              &nbsp;&nbsp;<span>Model</span>
          </template>
          
          <n-flex vertical>

            <n-card>
              This dashboard simulates several models of economic growth that are commonly found in undergraduate macroeconomics and growth courses.
            </n-card>
            
            <n-radio-group v-model:value="model_chosen" name="radiobuttongroup1">
              <n-radio-button
                v-for="model in models"
                :key="model.value"
                :value="model.value"
                :label="model.label"
              />
            </n-radio-group>

          </n-flex>
        </n-tab-pane>

        <n-tab-pane name="aggregates">
          <template #tab>
              <FontAwesomeIcon icon="globe" />
              &nbsp;&nbsp;<span>Aggregates</span>
          </template>
          <n-card :bordered="false" size="small">
          <n-grid cols="2 s:1 m:1 l:2 xl:3 2xl:5" responsive="screen" :x-gap="16" :y-gap="16">
            <n-grid-item>
              <VariablePlot variable="Y" label="Output" latex-expression="Y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="A" label="TFP" latex-expression="A" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="K" label="Capital" latex-expression="K" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="L" label="Labor" latex-expression="L" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="C" label="Consumption" latex-expression="C" :data-table="data_table" />
            </n-grid-item>
          </n-grid>
          </n-card>
        </n-tab-pane>
        
        <n-tab-pane name="per_capita">
          <template #tab>
              <FontAwesomeIcon icon="person" />
              &nbsp;&nbsp;<span>Per Capita</span>
          </template>
          <n-card :bordered="false" size="small">
          <n-grid cols="2 s:1 m:1 l:2 xl:3 2xl:5" responsive="screen" :x-gap="16" :y-gap="16">
            <n-grid-item>
              <VariablePlot variable="y" label="Output per Capita" latex-expression="y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="k" label="Capital per Capita" latex-expression="k" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="x" label="Land per Capita" latex-expression="x" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="c" label="Consumption per Capita" latex-expression="c" :data-table="data_table" />
            </n-grid-item>
          </n-grid>
          </n-card>
        </n-tab-pane>


        <n-tab-pane name="growth">
          <template #tab>
                <FontAwesomeIcon icon="arrow-trend-up" />
              &nbsp;&nbsp;<span>Growth Rates</span>
          </template>
          <n-card :bordered="false" size="small">
          <n-grid cols="2 s:1 m:1 l:2 xl:3 2xl:5" responsive="screen" :x-gap="16" :y-gap="16">
            <n-grid-item>
              <VariablePlot variable="g_Y" label="Growth Rate of Output" latex-expression="g_Y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="g_A" label="Growth Rate of TFP" latex-expression="g_A" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="g_K" label="Growth Rate of Capital" latex-expression="g_K" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="g_L" label="Growth Rate of Labor" latex-expression="g_L" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="g_C" label="Growth Rate of Consumption" latex-expression="g_C" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="g_y" label="Growth Rate of Output per Capita" latex-expression="g_y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="g_k" label="Growth Rate of Capital per Capita" latex-expression="g_k" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item>
              <VariablePlot variable="g_c" label="Growth Rate of Consumption per Capita" latex-expression="g_c" :data-table="data_table" />
            </n-grid-item>
          </n-grid>
          </n-card>
        </n-tab-pane>
        

        <n-tab-pane name="table">
          <template #tab>
              <FontAwesomeIcon icon="table" />
              &nbsp;&nbsp;<span>Table</span>
          </template>
          <n-card :bordered="false" size="small">
          <n-data-table
            :columns="data_table_columns"
            :data="data_table"
            :bordered="true"
            max-height="calc(100vh - 150px)"
            :scroll-x="1800"
            striped
          />
        </n-card>
        </n-tab-pane>

      </n-tabs>
      </n-layout>
      
    </n-layout>
    </n-layout>
  </n-config-provider>
</template>

<style scoped>

  .n-collapse-item__content-inner {
    padding: 50px 0;
  }

</style>
