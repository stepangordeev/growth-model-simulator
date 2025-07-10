<script setup>
import HelloWorld from './components/HelloWorld.vue'
import TheWelcome from './components/TheWelcome.vue'
import { defineComponent, ref } from "vue";

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
</script>

<template>
  aaa
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
</template>

<style scoped>
</style>
