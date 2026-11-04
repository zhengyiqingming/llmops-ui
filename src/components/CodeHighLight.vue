<script setup lang="ts">
import { onMounted, ref, useSlots } from 'vue'
import hljs from 'highlight.js/lib/common'
import 'highlight.js/styles/github-dark.css'

// 1.定义自定义组件所需数据
const props = defineProps({
  language: { type: String, default: '', required: true },
})
const codeElement = ref(null)
const slots = useSlots()
// 2.组件在挂载成功后高亮代码
onMounted(() => {
  if (codeElement.value) {
    hljs.highlightElement(codeElement.value)
  }
})
</script>
<!--使用插槽写法：默认插槽-->
<template>
  <pre
    class="mb-4"
  ><code ref="codeElement" :class="`language-${props.language} whitespace-pre`"><slot></slot></code></pre>
</template>

<style scoped></style>
