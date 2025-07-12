<script setup>
import { ref, computed } from 'vue'
import { VueLatex } from 'vatex'

// Define props
const props = defineProps({
  modelValue: {
    type: Number,
    required: true
  },
  min: {
    type: Number,
    required: true
  },
  max: {
    type: Number,
    required: true
  },
  step: {
    type: Number,
    required: true
  },
  latexExpression: {
    type: String,
    required: true
  },
  title: {
    type: String,
    required: true
  }
})

// Define emits for v-model
const emit = defineEmits(['update:modelValue'])

// Computed property for marks
const marks = computed(() => createLabeledMarks(props.min, props.max, props.step, props.modelValue))

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

</script>

<template>
    <n-tooltip :disabled="false">
      <template #trigger>
        <n-slider 
          :value="props.modelValue"
          @update:value="emit('update:modelValue', $event)"
          :marks="marks" 
          :max="props.max" 
          step="mark" 
          :tooltip="false"
        >
          <template #thumb>
            <n-icon-wrapper :size="24" :border-radius="12">
              <vue-latex :expression="props.latexExpression" fontsize="14" display-mode style="color: var(--n-text-color);"/>
            </n-icon-wrapper>
          </template>
        </n-slider>
      </template>
      {{ props.title }}
    </n-tooltip>
</template>

<style scoped>
.n-slider {
  padding: 15px 0;
}
</style>