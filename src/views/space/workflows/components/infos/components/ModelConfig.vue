<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { apiPrefix } from '@/config'
import { useGetLanguageModel, useGetLanguageModels } from '@/hooks/use-language-model'
import { useUpdateDraftAppConfig } from '@/hooks/use-app'

// 1.定义自定义组件所需数据
const props = defineProps({
  model_config: { type: Object, default: {}, required: true },
})
const emits = defineEmits(['update:model_config'])
const form = ref<any>({})
const {
  loading: getLanguageModelLoading,
  language_model,
  loadLanguageModel,
} = useGetLanguageModel()
const { language_models, loadLanguageModels } = useGetLanguageModels()
const modelOptions = computed(() => {
  return language_models.value.map((language_model) => {
    return {
      isGroup: true,
      label: language_model.label,
      options: language_model.models.map((model) => {
        return {
          label: model.label,
          value: `${language_model.name}/${model.model_name}`,
        }
      }),
    }
  })
})

// 2.定义选择模型处理器
const changeModel = (value: any): any => {
  // 2.1 使用/拆分出提供商+模型名字
  const [provider_name, model_name] = value.split('/')

  // 2.2 发起请求获取模型详情
  loadLanguageModel(provider_name, model_name).then(() => {
    // 2.3 重新赋值parameters
    form.value.parameters = language_model.value.parameters.reduce(
      (acc: Record<string, any>, parameter: Record<string, any>) => {
        acc[parameter.name] = parameter.default ?? null
        return acc
      },
      {} as Record<string, any>,
    )
  })
}

// 3.触发器隐藏处理器，提交数据进行更新
const hideModelTrigger = () => {
  // 3.1 处理表单数据
  const [provider_name, model_name] = form.value.selectValue.split('/')

  // 3.2 提取表单模型配置
  const model_config = {
    provider: provider_name,
    model: model_name,
    parameters: form.value.parameters,
  }

  // 3.3 提交应用草稿配置更新
  emits('update:model_config', model_config)
}

watch(
  () => props.model_config,
  (newValue) => {
    // 1.完成表单数据初始化
    form.value['selectValue'] = `${newValue?.provider}/${newValue.model}`
    form.value['provider'] = newValue?.provider
    form.value['model'] = newValue?.model
    form.value['parameters'] = newValue?.parameters

    // 2.请求语言模型详情API接口
    newValue?.provider && loadLanguageModel(String(newValue?.provider), String(newValue?.model))
  },
  { immediate: true },
)

onMounted(() => {
  loadLanguageModels()
})
</script>

<template>
  <a-trigger
    v-if="props.model_config?.provider"
    trigger="click"
    position="br"
    :popup-translate="[0, 12]"
    @hide="hideModelTrigger"
  >
    <div class="flex items-center gap-1 cursor-pointer hover:bg-gray-100 px-1.5 py-1 rounded-lg">
      <a-avatar
        :size="16"
        shape="square"
        :image-url="`${apiPrefix}/language-models/${form?.provider}/icon`"
      />
      <div class="text-gray-700 text-xs">{{ form?.model }}</div>
      <icon-down />
    </div>
    <template #content>
      <div class="bg-white px-6 py-5 shadow rounded-lg w-[460px]">
        <!-- 标题 -->
        <div class="text-gray-700 text-base font-semibold mb-3">模型设置</div>
        <!-- 模型选择 -->
        <div class="flex flex-col gap-2 mb-2">
          <div class="text-gray-700">模型</div>
          <a-select
            :options="modelOptions"
            v-model:model-value="form.selectValue"
            size="small"
            class="rounded-lg mb-2"
            placeholder="请选择Agent使用的大语言模型"
            @change="changeModel"
          >
            <!--data 是 Arco Design a-select 插槽参数，它代表当前被渲染的那个 option 对象，也就是 modelOptions 里 options 数组的单个元素-->
            <!--    data.value = "语言模型名/模型名"，例如 "openai/gpt-4o" ，data.label = model.label（模型展示名）         -->
            <!--      插槽	    触发时机	              data 是谁
                      #label	已选中值回显到选择框时	  选中的那个叶子 option 对象
                      #option	下拉面板里逐个渲染选项时	当前正在渲染的叶子 option 对象      -->
            <template #label="{ data }">
              <div class="flex items-center gap-2">
                <a-avatar
                  :size="16"
                  shape="square"
                  :image-url="`${apiPrefix}/language-models/${data.value.split('/')[0]}/icon`"
                />
                <a-space :size="4">
                  <div class="text-xs text-gray-700">{{ data.value.split('/')[0] }}</div>
                  <div class="text-xs text-gray-500">·</div>
                  <div class="text-xs text-gray-700">{{ data.value.split('/')[1] }}</div>
                </a-space>
              </div>
            </template>
            <template #option="{ data }">
              <div class="flex items-center gap-2">
                <a-avatar
                  :size="16"
                  shape="square"
                  :image-url="`${apiPrefix}/language-models/${data.value.split('/')[0]}/icon`"
                />
                <div class="text-xs text-gray-700 py-2">{{ data.label }}</div>
              </div>
            </template>
          </a-select>
        </div>
        <!-- 参数列表 -->
        <div class="text-gray-700 mb-2">参数</div>
        <a-spin :loading="getLanguageModelLoading" class="w-full">
          <div
            v-for="parameter in language_model?.parameters"
            class="flex items-center gap-2 h-8 mb-4"
          >
            <!-- 字段标签 -->
            <div class="flex items-center gap-2 text-gray-500 w-[120px] flex-shrink-0">
              <div class="text-xs">{{ parameter?.label }}</div>
              <a-tooltip :content="parameter?.help">
                <icon-question-circle />
              </a-tooltip>
            </div>
            <!-- 字段输入框 -->
            <!--  v-model:model-value（双向绑定）：这是受控模式。只要绑定了这个属性，组件的值就完全且只受绑定的变量控制。变量里是啥，组件就显示啥。
            :default-value（默认值）：这是非受控模式下的初始值。只有当组件没有被 v-model 或 model-value 绑定时，它才会起作用。          -->
            <template v-if="parameter?.options?.length > 0">
              <a-select
                v-model:model-value="form.parameters[parameter.name]"
                :default-value="parameter.default"
                placeholder="请选择参数值"
                :options="parameter.options"
              />
            </template>
            <template v-else-if="parameter.type === 'boolean'">
              <a-select
                v-model:model-value="form.parameters[parameter.name]"
                :default-value="parameter.default"
                placeholder="请选择参数值"
                :options="[
                  { label: '是', value: true },
                  { label: '否', value: false },
                ]"
              />
            </template>
            <template v-else-if="['int', 'float'].includes(parameter.type)">
              <a-slider
                v-model:model-value="form.parameters[parameter.name]"
                :default-value="parameter.default"
                :min="parameter?.min"
                :max="parameter?.max"
                :step="parameter?.type === 'float' ? 0.1 : 1"
                show-input
              />
            </template>
            <template v-else-if="parameter.type === 'string'">
              <a-input
                v-model:model-value="form.parameters[parameter.name]"
                :default-value="parameter.default"
                placeholder="请输入参数值"
              />
            </template>
          </div>
        </a-spin>
      </div>
    </template>
  </a-trigger>
</template>

<style scoped></style>
