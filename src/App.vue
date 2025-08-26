<script setup>
import { defineComponent, ref, computed, h, watch, provide } from "vue";
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
const b1 = ref(0);
const d0 = ref(0);
const d1 = ref(0);
const z = ref(0);
const s = ref(0.3);
const rho = ref(0);
const X = ref(1);
const T = ref(200);


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

const L_lom = (L_prev, b0, b1, d0, d1, y) => {
  return L_prev * (1 + b0 + b1*y - d0 - d1 * y);
};

const K_lom = (K, I_y, delta) => {
  return K * (1 - delta) + I_y;
};

// Simulation function converted from R
const simulate = (
  L_1,
  K_1,
  A_1,
  alpha,
  beta,
  gamma,
  delta,
  phi,
  theta,
  b0,
  b1,
  d0,
  d1,
  z,
  s,
  rho,
  X,
  T
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
  Y_arr[0] = Y(A_arr[0], K_arr[0], X, L_arr[0] * (1 - rho), gamma, alpha, beta);
  I_y_arr[0] = I_y(Y_arr[0], s);
  I_a_arr[0] = I_a(A_arr[0], K_arr[0], L_arr[0] * rho, z, phi, theta);
  C_arr[0] = Y_arr[0] - I_y_arr[0];
  y_arr[0] = Y_arr[0] / L_arr[0];
  k_arr[0] = K_arr[0] / L_arr[0];
  x_arr[0] = X / L_arr[0];
  c_arr[0] = C_arr[0] / L_arr[0];

  // Simulate forward
  for (let t = 0; t < T - 1; t++) {
    A_arr[t + 1] = A_lom(A_arr[t], I_a_arr[t]);
    L_arr[t + 1] = L_lom(L_arr[t], b0, b1, d0, d1, y_arr[t]);
    K_arr[t + 1] = K_lom(K_arr[t], I_y_arr[t], delta);
    Y_arr[t + 1] = Y(A_arr[t + 1], K_arr[t + 1], X, L_arr[t + 1] * (1 - rho), gamma, alpha, beta);
    I_y_arr[t + 1] = I_y(Y_arr[t + 1], s);
    I_a_arr[t + 1] = I_a(A_arr[t + 1], K_arr[t + 1], L_arr[t + 1] * rho, z, phi, theta);
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
  b1.value, // b1
  d0.value, // d0
  d1.value, // d1
  z.value, // z
  s.value, // s
  rho.value, // rho
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
    label: "Endogenous"
  },
  {
    value: "Jones",
    label: "Semi-Endogenous"
  },
  {
    value: "Automation",
    label: "AI"
  },
  {
    value: "Empty",
    label: "Empty Planet"
  },
  {
    value: "General",
    label: "General"
  }
]

// Parameter presets for each model
const modelPresets = {
  Solow: {
    L_1: 1,
    K_1: 1,
    A_1: 1,
    alpha: 0.3,
    beta: 0,
    gamma: 1,
    delta: 0.1,
    phi: 0,
    theta: 0,
    b0: 0,
    b1: 0,
    d0: 0,
    d1: 0,
    z: 0,
    s: 0.3,
    rho: 0,
    X: 1
  },
  Malthus: {
    L_1: 1,
    K_1: 1,
    A_1: 1,
    alpha: 0,
    beta: 0.3,
    gamma: 1,
    delta: 0,
    phi: 0,
    theta: 0,
    b0: 0.01,
    b1: 0,
    d0: 0.02,
    d1: -0.01,
    z: 0,
    s: 0,
    rho: 0,
    X: 1
  },
  Romer: {
    L_1: 1,
    K_1: 1,
    A_1: 1,
    alpha: 0.3,
    beta: 0,
    gamma: 1,
    delta: 0.1,
    phi: 1,
    theta: 0,
    b0: 0,
    b1: 0,
    d0: 0,
    d1: 0,
    z: 0.1,
    s: 0.3,
    rho: 0.1,
    X: 1
  },
  Jones: {
    L_1: 1,
    K_1: 1,
    A_1: 1,
    alpha: 0.3,
    beta: 0,
    gamma: 0.5,
    delta: 0.1,
    phi: 0,
    theta: 0,
    b0: 0.01,
    b1: 0,
    d0: 0,
    d1: 0,
    z: 0.1,
    s: 0.3,
    rho: 0.1,
    X: 1
  },
  Automation: {
    L_1: 1,
    K_1: 1,
    A_1: 1,
    alpha: 0.3,
    beta: 0,
    gamma: 0.5,
    delta: 0.1,
    phi: 0.5,
    theta: 0.3,
    b0: 0.01,
    b1: 0,
    d0: 0,
    d1: 0,
    z: 0.1,
    s: 0.3,
    rho: 0.1,
    X: 1
  },
  Empty: {
    L_1: 1,
    K_1: 1,
    A_1: 1,
    alpha: 0.3,
    beta: 0,
    gamma: 0.5,
    delta: 0.1,
    phi: 0,
    theta: 0,
    b0: 0.02,
    b1: -0.01,
    d0: 0,
    d1: 0,
    z: 0.1,
    s: 0.3,
    rho: 0.1,
    X: 1
  },
  General: {
    L_1: 1,
    K_1: 1,
    A_1: 1,
    alpha: 0.3,
    beta: 0,
    gamma: 1,
    delta: 0.1,
    phi: 0,
    theta: 0,
    b0: 0,
    b1: 0,
    d0: 0,
    d1: 0,
    z: 0,
    s: 0.3,
    rho: 0,
    X: 1
  }
};

// Define which models should hide each parameter (keep them at default values)
const parameterVisibility = {
  alpha: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty', 'Automation'] }, // Capital share not used in Malthus
  beta: { hiddenInModels: ['Solow', 'Romer', 'Jones', 'Empty', 'Automation'] }, // Land share only used in Malthus and General
  gamma: { hiddenInModels: ['Solow', 'Malthus', 'Romer'] }, // TFP returns to scale only used in Jones and General
  delta: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty'] }, // Depreciation only used in capital models
  phi: { hiddenInModels: ['Solow', 'Malthus', 'Romer', 'Jones', 'Empty'] },
  theta: { hiddenInModels: ['Solow', 'Malthus', 'Romer', 'Jones', 'Empty'] }, // Research automation only used in General
  b0: { hiddenInModels: ['Solow', 'Romer'] }, // Birth rate only used in Malthus, Jones, and General
  b1: { hiddenInModels: ['Solow', 'Malthus', 'Romer', 'Jones'] }, // Birth rate decline only used in General
  d0: { hiddenInModels: ['Solow', 'Romer', 'Jones', 'Empty', 'Automation'] }, // Base death rate only used in Malthus and General
  d1: { hiddenInModels: ['Solow', 'Romer', 'Jones', 'Empty', 'Automation'] }, // Death rate decline only used in Malthus and General
  z: { hiddenInModels: ['Solow', 'Malthus'] }, // Research productivity only used in Romer, Jones, and General
  s: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty'] }, // Savings rate only used in capital models
  rho: { hiddenInModels: ['Solow', 'Malthus'] }, // Researcher share only used in Romer, Jones, and General
  X: { hiddenInModels: ['Solow', 'Romer', 'Jones', 'Empty', 'Automation'] }, // Research productivity only used in Romer, Jones, and General
  L_1: { hiddenInModels: [] }, // Initial population used in all models
  K_1: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty'] }, // Initial capital used in all models
  A_1: { hiddenInModels: [] }, // Initial TFP used in all models
  T: { hiddenInModels: [] } // Simulation periods used in all models
};

// Define which models should hide each variable/graph
const variableVisibility = {
  // Aggregates
  Y: { hiddenInModels: [] }, // Output always relevant
  A: { hiddenInModels: [] }, // TFP always relevant
  K: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty'] }, // Capital not used in Malthus
  L: { hiddenInModels: [] }, // Labor always relevant
  C: { hiddenInModels: [] },
  
  // Per capita
  y: { hiddenInModels: [] }, // Output per capita always relevant
  k: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty'] }, // Capital per capita not used in Malthus
  x: { hiddenInModels: ['Solow', 'Romer', 'Jones', 'Empty', 'Automation'] }, // Land per capita only in Malthus and General
  c: { hiddenInModels: [] }, 
  
  // Growth rates
  g_Y: { hiddenInModels: [] }, // Output growth always relevant
  g_A: { hiddenInModels: ['Solow', 'Malthus'] }, // TFP growth only in research models
  g_K: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty'] }, // Capital growth not used in Malthus
  g_L: { hiddenInModels: ['Solow', 'Romer'] }, // Population growth only in Malthus, Jones, General
  g_C: { hiddenInModels: [] }, 
  g_y: { hiddenInModels: [] }, // Output per capita growth always relevant
  g_k: { hiddenInModels: ['Malthus', 'Romer', 'Jones', 'Empty'] }, // Capital per capita growth not used in Malthus
  g_c: { hiddenInModels: [] }, 
};

// Helper function to check if a parameter should be visible
const isParameterVisible = (parameterName) => {
  const visibility = parameterVisibility[parameterName];
  if (!visibility) return true;
  return !visibility.hiddenInModels.includes(model_chosen.value);
};

// Helper function to check if a variable should be visible
const isVariableVisible = (variableName) => {
  const visibility = variableVisibility[variableName];
  if (!visibility) return true;
  return !visibility.hiddenInModels.includes(model_chosen.value);
};

// Provide functions and reactive data to child components
provide('isParameterVisible', isParameterVisible);
provide('isVariableVisible', isVariableVisible);
provide('model_chosen', model_chosen);

// Watch for model changes and apply presets
watch(model_chosen, (newModel) => {
  const preset = modelPresets[newModel];
  if (preset) {
    L_1.value = preset.L_1;
    K_1.value = preset.K_1;
    A_1.value = preset.A_1;
    alpha.value = preset.alpha;
    beta.value = preset.beta;
    gamma.value = preset.gamma;
    delta.value = preset.delta;
    phi.value = preset.phi;
    theta.value = preset.theta;
    b0.value = preset.b0;
    b1.value = preset.b1;
    d0.value = preset.d0;
    d1.value = preset.d1;
    z.value = preset.z;
    s.value = preset.s;
    rho.value = preset.rho;
    X.value = preset.X;
  }
}, { immediate: true }); // Apply preset immediately when component mounts

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

    <n-layout-header style="padding: 10px 20px;" bordered>

      <n-flex justify="space-between" align-items="center">

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

        <n-collapse :default-expanded-names="['production', 'capital', 'population', 'research', 'initial', 'simulation']">

          <n-collapse-item name="production" title="Production Function">
            <template #header-extra>
              <FontAwesomeIcon icon="hammer" />
            </template>
            <ParameterSlider v-model="alpha" parameter-name="alpha" :min="0" :max="1" :step="0.1" latex-expression="\alpha" title="capital share" />
            <ParameterSlider v-model="beta" parameter-name="beta" :min="0" :max="1" :step="0.1" latex-expression="\beta" title="land share" />
            <ParameterSlider v-model="gamma" parameter-name="gamma" :min="0" :max="1" :step="0.1" latex-expression="\gamma" title="TFP returns to scale" />
          </n-collapse-item>
          
          <n-collapse-item name="capital" title="Capital Dynamics">
            <template #header-extra>
              <FontAwesomeIcon icon="industry" />
            </template>
            <ParameterSlider v-model="delta" parameter-name="delta" :min="0" :max="1" :step="0.1" latex-expression="\delta" title="depreciation rate" />
            <ParameterSlider v-model="s" parameter-name="s" :min="0" :max="1" :step="0.1" latex-expression="s" title="savings rate" />
          </n-collapse-item>
          
          <n-collapse-item name="population" title="Population Dynamics">
            <template #header-extra>
              <FontAwesomeIcon icon="baby-carriage" />
            </template>
            <ParameterSlider v-model="b0" parameter-name="b0" :min="0" :max="0.1" :step="0.01" latex-expression="b" title="birth rate" />
            <ParameterSlider v-model="b1" parameter-name="b1" :min="-0.05" :max="0.05" :step="0.01" latex-expression="b_y" title="birth rate change with income" />
            <ParameterSlider v-model="d0" parameter-name="d0" :min="0" :max="0.1" :step="0.01" latex-expression="d" title="base death rate" />
            <ParameterSlider v-model="d1" parameter-name="d1" :min="-0.05" :max="0.05" :step="0.01" latex-expression="d_y" title="death rate change with income" />
          </n-collapse-item>
          
          <n-collapse-item name="research" title="Research Dynamics">
            <template #header-extra>
              <FontAwesomeIcon icon="flask" />
            </template>
            <ParameterSlider v-model="z" parameter-name="z" :min="0" :max="1" :step="0.1" latex-expression="z" title="research productivity" />
            <ParameterSlider v-model="phi" parameter-name="phi" :min="0" :max="1" :step="0.1" latex-expression="\phi" title="research returns to scale" />
            <ParameterSlider v-model="theta" parameter-name="theta" :min="0" :max="1" :step="0.1" latex-expression="\theta" title="research automation" />
            <ParameterSlider v-model="rho" parameter-name="rho" :min="0" :max="1" :step="0.1" latex-expression="\rho" title="researcher share" />
          </n-collapse-item>
          
          <n-collapse-item name="initial" title="Initial Values">
            <template #header-extra>
              <FontAwesomeIcon icon="rocket" />
            </template>
            <ParameterSlider v-model="K_1" parameter-name="K_1" :min="1" :max="10" :step="1" latex-expression="K_1" title="initial capital" />
            <ParameterSlider v-model="L_1" parameter-name="L_1" :min="1" :max="10" :step="1" latex-expression="L_1" title="initial population" />
            <ParameterSlider v-model="A_1" parameter-name="A_1" :min="1" :max="10" :step="1" latex-expression="A_1" title="initial TFP" />
            <ParameterSlider v-model="X" parameter-name="X" :min="1" :max="10" :step="1" latex-expression="X" title="permanent land" />
          </n-collapse-item>

          <n-collapse-item name="simulation" title="Simulation Settings">
            <template #header-extra>
              <FontAwesomeIcon icon="gamepad" />
            </template>
            <ParameterSlider v-model="T" parameter-name="T" :min="50" :max="500" :step="50" latex-expression="T" title="number of time periods" />
          </n-collapse-item>

        </n-collapse>
      </n-layout-sider>

      <n-layout-content content-style="padding: 0px 24px;">
      
      <n-tabs type="line" animated>
        
        <n-tab-pane name="model">
          <template #tab>
              <FontAwesomeIcon icon="star" />
              &nbsp;&nbsp;<span>Model</span>
          </template>
          
          <n-flex vertical>

            <n-card>
              This dashboard simulates several models of economic growth that are commonly found in undergraduate macroeconomics and growth courses.
              Choose the model to simulate using the selector below. Simulation results can be explored using the tabs above. Model parameters can be adjusted using the sliders in the sidebar. When the model is switched, parameters are reset to default values for the chosen model.
            </n-card>
            
            <n-radio-group v-model:value="model_chosen" name="radiobuttongroup1">
              <n-radio-button
                v-for="model in models"
                :key="model.value"
                :value="model.value"
                :label="model.label"
              />
            </n-radio-group>
            
            <n-card v-if="model_chosen === 'Solow'">

              <p>The Solow growth model was originally developed in <a href="https://doi.org/10.2307/1884513" class="reference">Solow (1956)</a>. The simplified version of the model presented here closely follows <a href="https://wwnorton.com/books/9781324063612" class="reference">Jones (2024, ch. 5)</a>. It focuses on capital accumulation and forms the backbone of many modern growth models.</p>

              <p>
                The model illustrates how the accumulation of capital can be behind short- and medium-run growth as the economy converges to a steady state. Sustained long-run growth cannot be attained by capital accumulation alone due to the diminishing returns to capital: at some point, the additional output produced by adding more capital cannot cover the depreciation of existing capital, leading to stagnation.
              </p>

              <p>Sustained long-run growth (balanced growth path) in this model can only be achieved through exogenous growth in total factor productivity. The Solow model, however, is silent on where this TFP growth might be coming from.</p>

              <n-h6 prefix="bar">
                Production Function
              </n-h6>
                The final output good <vue-latex :expression="'Y_t'" /> is produced using a constant-returns-to-scale Cobb-Douglas production function. Production uses capital <vue-latex :expression="'K_t'" /> and labor <vue-latex :expression="'L_t'" />, with total factor productivity <vue-latex :expression="'A_t'" />:
                <vue-latex :expression="'Y_t = A_t K_t^\\alpha L_t^{1-\\alpha}'" display-mode />

              <n-h6 prefix="bar">
                Capital Law of Motion
              </n-h6>
                Capital depreciates at rate <vue-latex :expression="'\\delta'"/>, new investment <vue-latex :expression="'I_t'" /> is added to the existing capital stock:
                <vue-latex :expression="'K_{t+1} = (1 - \\delta) K_t + I_t'" display-mode />
              <n-h6 prefix="bar">
                Resource Constraint
              </n-h6>
                Output is used either for consumption <vue-latex :expression="'C_t'" /> or investment <vue-latex :expression="'I_t'" />:
                <vue-latex :expression="'Y_t = C_t + I_t'" display-mode />
              <n-h6 prefix="bar">
                Saving Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'s'" /> of output is saved and invested:
                <vue-latex :expression="'I_t = s Y_t'" display-mode />
              <n-h6 prefix="bar">
                Population Law of Motion
              </n-h6>
                Population grows at rate <vue-latex :expression="'b'"/>:
                <vue-latex :expression="'L_{t+1} = (1+b)L_t'" display-mode />
            </n-card>

            <n-card v-if="model_chosen === 'Malthus'">

              <p>The reasoning behind this model was formulated in <a href="https://www.jstor.org/stable/j.ctv1bvnf95" class="reference">Malthus (1798)</a>. Malthus believed that better living standards lead to greater population growth (e.g. because richer societies can afford better nutrition and healthcare). If, furthermore, the supply of land is fixed, then an increase in population density should decrease the average living standards. This generates a self-correcting force: any increase in living standards (e.g. thanks to better technology) is gradually offset by population growth, driving the society back to subsistence level at which everyone is poor enough that the number of births equals the number of deaths. This argument helps understand the largely constant average standard of living in the agricultural societies throughout most of human history, up to Malthus's time.</p>

              <p>While Malthus's work was not mathematical, his main insights can be translated into formal mathematical language of modern models of economic growth. One such formalization is presented below: it is inspired by <a href="https://doi.org/10.1257/00028280260344731" class="reference">Hansen and Prescott (2002)</a> and <a href="https://wwnorton.com/books/9781324059578" class="reference">Jones and Vollrath (2024, ch. 9)</a>.</p>


              <n-h6 prefix="bar">
                Production Function
              </n-h6>
                The final output good <vue-latex :expression="'Y_t'" /> is produced using a constant-returns-to-scale Cobb-Douglas production function. Production uses land <vue-latex :expression="'X'" /> and labor <vue-latex :expression="'L_t'" />, with total factor productivity <vue-latex :expression="'A_t'" />. Land is fixed at a constant level.
                <vue-latex :expression="'Y_t = A_t X^\\beta L_t^{1-\\beta}'" display-mode />

              <n-h6 prefix="bar">
                Population Law of Motion
              </n-h6>
                The birth rate is <vue-latex :expression="'b'" />. The base death rate is <vue-latex :expression="'d'" />. Furthermore, the death rate grows in income per capita <vue-latex :expression="'y_t=\\frac{Y_t}{L_t}'" /> at rate <vue-latex :expression="'d_y'" />. The Malthusian model requires this rate to be negative, so that the death rate declines with income (e.g. due to better healthcare). Thus, the growth rate of population is <vue-latex :expression="'b - (d +  d_y y_t)'" />, resulting in the following law of motion:
                <vue-latex :expression="'L_{t+1} = (1+b - (d + d_y y_t))L_t'" display-mode />
            </n-card>

            <n-card v-if="model_chosen === 'Romer'">

              <p>The endogenous growth model includes the production of new ideas within the model, instead of leaving the level of technology exogenous as in the Solow model. The level of TFP can be increased by researchers generating new ideas. The long-run growth rate of TFP along the balanced growth path is proportional to the number of workers engaged in research rather than final good production.</p>

              <p> The endogenous growth model was developed by <a href="https://doi.org/10.1086/261725" class="reference">Romer (1990)</a>, and so is often referred to as the Romer model. The simplified version of the model here builds on <a href="https://wwnorton.com/books/9781324063612" class="reference">Jones (2024, ch. 6)</a>.</p>

              <n-h6 prefix="bar">
                Production Function
              </n-h6>
                The final output good <vue-latex :expression="'Y_t'" /> is produced using a linear production function by labor employed in production <vue-latex :expression="'L_{y,t}'" /> with productivity <vue-latex :expression="'A_t'" />:
                <vue-latex :expression="'Y_t = A_t L_{y,t}'" display-mode />
              <n-h6 prefix="bar">
                Idea Production Function
              </n-h6>
                New ideas are produced using a linear function by researchers <vue-latex :expression="'L_{a,t}'" /> with research productivity <vue-latex :expression="'z'" />. The production of new ideas is proportional to the existing stock of ideas <vue-latex :expression="'A_t'" />:
                <vue-latex :expression="'I_{a,t} = z A_t L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Ideas Law of Motion
              </n-h6>
                Ideas accumulate over time through research and development (R&D). Old ideas don't depreciate, and the quantity of new ideas is <vue-latex :expression="'I_{a,t}'" />:
                <vue-latex :expression="'A_{t+1} = A_t + I_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Resource Constraint
              </n-h6>
                Population <vue-latex :expression="'L_t'" /> is split between workers employed in production <vue-latex :expression="'L_{y,t}'" /> and in research <vue-latex :expression="'L_{a,t}'" />:
                <vue-latex :expression="'L_t = L_{y,t} + L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Allocation Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'\\rho'" /> of workers become researchers:
                <vue-latex :expression="'L_{a,t} = \\rho L_t'" display-mode />
            </n-card>

            <n-card v-if="model_chosen === 'Jones'">

              <p>The semi-endogenous growth model drops the endogenous model's assumption that the production of new ideas is proportional to the existing stock of ideas. The problem with this assumption was that it led the endogenous growth model to predict that the long-run growth rate of TFP (and output per capita) along the balanced growth path is proportional to the number of researchers in the economy. But this contradicts empirical evidence: the growth rate has been fairly stable in developed countries in recent history even as the number of researchers and research effort has been growing steadily (<a href="https://doi.org/10.1257/aer.20180338" class="reference">Bloom et al., 2020</a>). The semi-endogenous growth model is able to match this fact: if the generation of new ideas is not proportional to the stock of existing ideas, then the long-run growth of TFP and output per capita depends on steady population growth. As a result, the growth rate of the economy along the balanced growth path is proportional to the growth rate of the number of researchers (and thus the the growth rate of population).</p>
                
              <p>Semi-endogenous growth theory was developed in <a href="https://doi.org/10.1086/262002" class="reference">Jones (1995)</a>. See <a href="https://doi.org/10.1146/annurev-economics-080521-012458" class="reference">Jones (2022)</a> for a recent overview. The simplified version of the model here builds on <a href="https://wwnorton.com/books/9781324063612" class="reference">Jones (2024, ch. 6)</a>.</p>

              <n-h6 prefix="bar">
                Production Function
              </n-h6>
                The final output good <vue-latex :expression="'Y_t'" /> is produced using a linear production function by labor employed in production <vue-latex :expression="'L_{y,t}'" /> with productivity <vue-latex :expression="'A_t'" />. Returns to ideas are <vue-latex :expression="'\\gamma'" />:
                <vue-latex :expression="'Y_t = A_t^\\gamma L_{y,t}'" display-mode />
              <n-h6 prefix="bar">
                Idea Production Function
              </n-h6>
                New ideas are produced using a linear function by researchers <vue-latex :expression="'L_{a,t}'" /> with research productivity <vue-latex :expression="'z'" />. The production of new ideas is <n-text italic>not</n-text> proportional to the existing stock of ideas <vue-latex :expression="'A_t'" />:
                <vue-latex :expression="'I_{a,t} = z L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Ideas Law of Motion
              </n-h6>
                Ideas accumulate over time through research and development (R&D). Old ideas don't depreciate, and the quantity of new ideas is <vue-latex :expression="'I_{a,t}'" />:
                <vue-latex :expression="'A_{t+1} = A_t + I_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Resource Constraint
              </n-h6>
                Population <vue-latex :expression="'L_t'" /> is split between workers employed in production <vue-latex :expression="'L_{y,t}'" /> and in research <vue-latex :expression="'L_{a,t}'" />:
                <vue-latex :expression="'L_t = L_{y,t} + L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Allocation Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'\\rho'" /> of workers become researchers:
                <vue-latex :expression="'L_{a,t} = \\rho L_t'" display-mode />
              <n-h6 prefix="bar">
                Population Law of Motion
              </n-h6>
                Population grows at rate <vue-latex :expression="'b'"/>:
                <vue-latex :expression="'L_{t+1} = (1+b)L_t'" display-mode />
            </n-card>

            <n-card v-if="model_chosen === 'Automation'">

              <p>
              This model is an extension of the semi-endogenous model that allows for automation in the idea production process. The formulation below is inspired by <a href="https://www.nber.org/books-and-chapters/economics-artificial-intelligence-agenda/artificial-intelligence-and-economic-growth" class="reference">Aghion, Jones, and Jones (2019, ch. 9)</a> and <a href="https://doi.org/10.1146/annurev-economics-080521-012458" class="reference">Jones (2022)</a>.
              </p>
              <p>In this model, ideas are produced by researches and artificial intelligence (represented with capital) rather than by researchers alone. This allows the model to escape the prediction of standard semi-endogenous theory that the long-run growth rate of TFP (and output per capita) must be proportional to the growth rate of population. Research automation in this model permits a balanced growth path even in the absence of population growth.
              </p>
              <p>
              At extreme levels of research automation, the model generates an even starker prediction. If research is sufficiently automated (capital share in idea production <vue-latex :expression="'\\theta'" /> is high enough), then the model generates a singularity: infinite TFP and GDP are reached within finite time. The simulation breaks at this point. The degree of automation needed for this to happen is determined by the returns to ideas in final good production (<vue-latex :expression="'\\gamma'" />) and in idea production (<vue-latex :expression="'\\phi'" />).
              </p>

              <n-h6 prefix="bar">
                Production Function
              </n-h6>
                The final output good <vue-latex :expression="'Y_t'" /> is produced using a linear production function by labor employed in production <vue-latex :expression="'L_{y,t}'" /> with productivity <vue-latex :expression="'A_t'" />. Returns to ideas are <vue-latex :expression="'\\gamma'" />:
                <vue-latex :expression="'Y_t = A_t^\\gamma L_{y,t}'" display-mode />
              <n-h6 prefix="bar">
                Idea Production Function
              </n-h6>
                New ideas are produced using a constant-returns-to-scale Cobb-Douglas production function. Idea production uses existing ideas <vue-latex :expression="'A_t'" />, capital <vue-latex :expression="'K_{t}'" /> and researchers <vue-latex :expression="'L_{a,t}'" />. Returns to existing ideas are <vue-latex :expression="'\\phi'" />:
                <vue-latex :expression="'I_{a,t} = z A_t^{\\phi} K_t^{\\theta} L_{a,t}^{1-\\theta}'" display-mode />
              <n-h6 prefix="bar">
                Ideas Law of Motion
              </n-h6>
                Ideas accumulate over time through research and development (R&D). Old ideas don't depreciate, and the quantity of new ideas is <vue-latex :expression="'I_{a,t}'" />:
                <vue-latex :expression="'A_{t+1} = A_t + I_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Capital Law of Motion
              </n-h6>
                Capital depreciates at rate <vue-latex :expression="'\\delta'"/>, new investment <vue-latex :expression="'I_t'" /> is added to the existing capital stock:
                <vue-latex :expression="'K_{t+1} = (1 - \\delta) K_t + I_t'" display-mode />
              <n-h6 prefix="bar">
                Saving Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'s'" /> of output is saved and invested:
                <vue-latex :expression="'I_t = s Y_t'" display-mode />
              <n-h6 prefix="bar">
                Labor Resource Constraint
              </n-h6>
                Population <vue-latex :expression="'L_t'" /> is split between workers employed in production <vue-latex :expression="'L_{y,t}'" /> and in research <vue-latex :expression="'L_{a,t}'" />:
                <vue-latex :expression="'L_t = L_{y,t} + L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Allocation Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'\\rho'" /> of workers become researchers:
                <vue-latex :expression="'L_{a,t} = \\rho L_t'" display-mode />
              <n-h6 prefix="bar">
                Population Law of Motion
              </n-h6>
                Population grows at rate <vue-latex :expression="'b'"/>:
                <vue-latex :expression="'L_{t+1} = (1+b)L_t'" display-mode />
            </n-card>

            <n-card v-if="model_chosen === 'Empty'">
              
              <p>This model extends the basic semi-endogenous growth model with a negative relationship between income and fertility. The formulation below is a simplified version of <a href="https://doi.org/10.1257/aer.20201605" class="reference">Jones (2022)</a>.</p>

              <p>If birth rates decline in income (as seems to be the case in the modern world, both within and across countries), the economy can get trapped in an "Empty Planet" steady state: instead of continued growth in population and output per capita (as in the standard semi-endogenous model), at some point people become so rich and have so few babies that population passes its peak and starts declining. Because population growth is essential for continued technological progress in the semi-endogenous model, this leads to stagnating output per capita for this vanishing population.</p>

              <n-h6 prefix="bar">
                Production Function
              </n-h6>
                The final output good <vue-latex :expression="'Y_t'" /> is produced using a linear production function by labor employed in production <vue-latex :expression="'L_{y,t}'" /> with productivity <vue-latex :expression="'A_t'" />. Returns to ideas are <vue-latex :expression="'\\gamma'" />:
                <vue-latex :expression="'Y_t = A_t^\\gamma L_{y,t}'" display-mode />
              <n-h6 prefix="bar">
                Idea Production Function
              </n-h6>
                New ideas are produced using a linear function by researchers <vue-latex :expression="'L_{a,t}'" /> with research productivity <vue-latex :expression="'z'" />. The production of new ideas is <n-text italic>not</n-text> proportional to the existing stock of ideas <vue-latex :expression="'A_t'" />:
                <vue-latex :expression="'I_{a,t} = z L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Ideas Law of Motion
              </n-h6>
                Ideas accumulate over time through research and development (R&D). Old ideas don't depreciate, and the quantity of new ideas is <vue-latex :expression="'I_{a,t}'" />:
                <vue-latex :expression="'A_{t+1} = A_t + I_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Resource Constraint
              </n-h6>
                Population <vue-latex :expression="'L_t'" /> is split between workers employed in production <vue-latex :expression="'L_{y,t}'" /> and in research <vue-latex :expression="'L_{a,t}'" />:
                <vue-latex :expression="'L_t = L_{y,t} + L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Allocation Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'\\rho'" /> of workers become researchers:
                <vue-latex :expression="'L_{a,t} = \\rho L_t'" display-mode />
              <n-h6 prefix="bar">
                Population Law of Motion
              </n-h6>
                The base birth rate is <vue-latex :expression="'b'" />. The birth rate grows in income per capita <vue-latex :expression="'y_t=\\frac{Y_t}{L_t}'" /> at rate <vue-latex :expression="'b_y'" />. The "Empty Planet" scenario requires this rate to be negative, so that fertility falls as incomes rise. Thus, the growth rate of population is <vue-latex :expression="'b + b_y y_t'" />, resulting in the following law of motion:
                <vue-latex :expression="'L_{t+1} = (1+b + b_y y_t ) L_t'" display-mode />
            </n-card>

            <n-card v-if="model_chosen === 'General'">

              <p>This is a general model that nests all of the special growth models in prior tabs. By adjusting the parameters, you can replicate any of those special models, or explore new ones.</p>

              <n-h6 prefix="bar">
                Production Function
              </n-h6>
                The final output good <vue-latex :expression="'Y_t'" /> is produced using a constant-returns-to-scale Cobb-Douglas production function. Production uses capital <vue-latex :expression="'K_t'" />, land <vue-latex :expression="'X_t'" />, and labor <vue-latex :expression="'L_t'" />, with total factor productivity <vue-latex :expression="'A_t'" />. Land is fixed at a constant level.
                <vue-latex :expression="'Y_t = A_t^\\gamma K_t^{\\alpha} X^{\\beta} L_t^{1-\\alpha-\\beta}'" display-mode />
              <n-h6 prefix="bar">
                Idea Production Function
              </n-h6>
                New ideas are produced using a constant-returns-to-scale Cobb-Douglas production function. Idea production uses existing ideas <vue-latex :expression="'A_t'" />, capital <vue-latex :expression="'K_{t}'" /> and researchers <vue-latex :expression="'L_{a,t}'" /> with research productivity <vue-latex :expression="'z'" />. Returns to existing ideas are <vue-latex :expression="'\\phi'" />:
                <vue-latex :expression="'I_{a,t} = z A_t^{\\phi} K_t^{\\theta} L_{a,t}^{1-\\theta}'" display-mode />
              <n-h6 prefix="bar">
                Ideas Law of Motion
              </n-h6>
                Ideas accumulate over time through research and development (R&D). Old ideas don't depreciate, and the quantity of new ideas is <vue-latex :expression="'I_{a,t}'" />:
                <vue-latex :expression="'A_{t+1} = A_t + I_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Capital Law of Motion
              </n-h6>
                Capital depreciates at rate <vue-latex :expression="'\\delta'"/>, new investment <vue-latex :expression="'I_t'" /> is added to the existing capital stock:
                <vue-latex :expression="'K_{t+1} = (1 - \\delta) K_t + I_t'" display-mode />
              <n-h6 prefix="bar">
                Population Law of Motion
              </n-h6>
                The base birth rate is <vue-latex :expression="'b'" />. The birth rate grows in income per capita <vue-latex :expression="'y_t=\\frac{Y_t}{L_t}'" /> at rate <vue-latex :expression="'b_y'" />. The base death rate is <vue-latex :expression="'d'" />. The death rate grows in income per capita at rate <vue-latex :expression="'d_y'" />. Thus, the growth rate of population is <vue-latex :expression="'b + b_y y_t - (d +  d_y y_t)'" />, resulting in the following law of motion:
                <vue-latex :expression="'L_{t+1} = (1+b + b_y y_t - (d + d_y y_t))L_t'" display-mode />
              <n-h6 prefix="bar">
                Resource Constraint
              </n-h6>
                Output is used either for consumption <vue-latex :expression="'C_t'" /> or investment <vue-latex :expression="'I_t'" />:
                <vue-latex :expression="'Y_t = C_t + I_t'" display-mode />
              <n-h6 prefix="bar">
                Saving Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'s'" /> of output is saved and invested:
                <vue-latex :expression="'I_t = s Y_t'" display-mode />
              <n-h6 prefix="bar">
                Labor Resource Constraint
              </n-h6>
                Population <vue-latex :expression="'L_t'" /> is split between workers employed in production <vue-latex :expression="'L_{y,t}'" /> and in research <vue-latex :expression="'L_{a,t}'" />:
                <vue-latex :expression="'L_t = L_{y,t} + L_{a,t}'" display-mode />
              <n-h6 prefix="bar">
                Labor Allocation Rule
              </n-h6>
                A constant fraction <vue-latex :expression="'\\rho'" /> of workers become researchers:
                <vue-latex :expression="'L_{a,t} = \\rho L_t'" display-mode />
            </n-card>

          </n-flex>
        </n-tab-pane>

        <n-tab-pane name="aggregates">
          <template #tab>
              <FontAwesomeIcon icon="globe" />
              &nbsp;&nbsp;<span>Aggregates</span>
          </template>
          <n-card :bordered="false" size="small">
          <n-grid cols="2 s:1 m:1 l:2 xl:3 2xl:5" responsive="screen" :x-gap="16" :y-gap="16">
            <n-grid-item v-if="isVariableVisible('Y')">
              <VariablePlot variable="Y" label="Output" latex-expression="Y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('A')">
              <VariablePlot variable="A" label="TFP" latex-expression="A" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('K')">
              <VariablePlot variable="K" label="Capital" latex-expression="K" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('L')">
              <VariablePlot variable="L" label="Labor" latex-expression="L" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('C')">
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
            <n-grid-item v-if="isVariableVisible('y')">
              <VariablePlot variable="y" label="Output per Capita" latex-expression="y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('k')">
              <VariablePlot variable="k" label="Capital per Capita" latex-expression="k" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('x')">
              <VariablePlot variable="x" label="Land per Capita" latex-expression="x" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('c')">
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
            <n-grid-item v-if="isVariableVisible('g_Y')">
              <VariablePlot variable="g_Y" label="Growth Rate of Output" latex-expression="g_Y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('g_A')">
              <VariablePlot variable="g_A" label="Growth Rate of TFP" latex-expression="g_A" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('g_K')">
              <VariablePlot variable="g_K" label="Growth Rate of Capital" latex-expression="g_K" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('g_L')">
              <VariablePlot variable="g_L" label="Growth Rate of Labor" latex-expression="g_L" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('g_C')">
              <VariablePlot variable="g_C" label="Growth Rate of Consumption" latex-expression="g_C" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('g_y')">
              <VariablePlot variable="g_y" label="Growth Rate of Output per Capita" latex-expression="g_y" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('g_k')">
              <VariablePlot variable="g_k" label="Growth Rate of Capital per Capita" latex-expression="g_k" :data-table="data_table" />
            </n-grid-item>
            <n-grid-item v-if="isVariableVisible('g_c')">
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
      </n-layout-content>
      
    </n-layout>
    </n-layout>
  </n-config-provider>
</template>

<style scoped>

  .n-collapse-item__content-inner {
    padding: 50px 0;
  }

  a.reference {
    border-bottom: 1px dashed var(--n-text-color) !important;
    color: var(--n-text-color) !important;
    text-decoration: none;
  }
  a.reference:hover {
    border-bottom: 1px solid var(--n-text-color) !important;
  }

</style>
