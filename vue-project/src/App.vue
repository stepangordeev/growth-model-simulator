<script setup>
import { VisXYContainer, VisLine, VisAxis, VisTooltip, VisCrosshair} from '@unovis/vue'
import { defineComponent, ref, computed } from "vue";
import { VueDataUi } from 'vue-data-ui';
import "vue-data-ui/style.css";

const value = ref(0);
const alpha = ref(0.3);
// marks from 0 to 1 in 0.1 increments
const marks = Object.fromEntries(
  Array.from({ length: 11 }, (_, i) => {
    const val = (i / 10).toFixed(1);
    return [parseFloat(val), val];
  })
);
// marks without labels
const marks_unlabeled = Object.fromEntries(
  Array.from({ length: 11 }, (_, i) => {
    const val = (i / 10).toFixed(1);
    return [parseFloat(val), ''];
  })
);
// marks with labels only for 0 and 1
const marks_labeled = Object.fromEntries(
  Array.from({ length: 11 }, (_, i) => {
    const val = (i / 10).toFixed(1);
    // if 0: label is "0", if 1: label is "1", otherwise no label
    let label;
    if (i === 0){
      label = "0";     
    } else if (i === 10) {
      label = "1";
    } else {
      label = "";
    }

    return [parseFloat(val), label];
  })
);
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


const data = computed(() =>
  Array.from({ length: 10 }, (_, i) => {
    const t = i + 1;
    return { t, y: Math.pow(t, alpha.value) };
  })
);

const triggers = {
  // [Line.selectors.line]: () => 'Average value'
}
const crosshair_tooltip_template = (d, x) => {
  return `<div>
    <strong>t:</strong> ${d.t.toFixed(0)}<br/>
    <strong>y:</strong> ${d.y.toFixed(3)}
  </div>`;
};

const dataset = ref([
  {
    "name": "Y",
    "series": [
      0,
      1,
      2,
      3,
      5,
      8,
      13,
      21,
      34,
      55,
      89,
      144
    ],
    "type": "line"
  }
])

</script>

<template>
  <n-layout has-sider>
    <n-layout-sider content-style="padding: 24px;">

      <n-divider>Parameters</n-divider>
      <n-collapse>
        <n-collapse-item title="Production Function">
          <n-slider
            v-model:value="alpha" :marks="createLabeledMarks(0, 1, 0.1)" max="1"
            step="mark" show-tooltip="true"
          >
            <template #thumb>
              <n-icon-wrapper :size="24" :border-radius="12">
                a
              </n-icon-wrapper>
            </template>
          </n-slider>
        </n-collapse-item>
      <n-collapse-item title="Capital Dynamics">
      </n-collapse-item>
      </n-collapse>
    </n-layout-sider>
      <!-- <VisXYContainer :data="data" :yDomainMinConstraint="[undefined, 0]" >
        <VisLine :x="d => d.t" :y="d => d.y" />
        <VisAxis type="x" label="Period"/>
        <VisAxis type="y" />
        <VisTooltip/>
        <VisCrosshair :template="crosshair_tooltip_template"/>
      </VisXYContainer> -->
      <VueDataUi
            component="VueUiXy"
            :dataset="dataset"
      />
  </n-layout>
</template>

<style scoped>
</style>
