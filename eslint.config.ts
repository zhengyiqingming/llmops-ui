import { globalIgnores } from 'eslint/config'
import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'
import pluginVue from 'eslint-plugin-vue'
import pluginVitest from '@vitest/eslint-plugin'
import skipFormatting from '@vue/eslint-config-prettier/skip-formatting'

// To allow more languages other than `ts` in `.vue` files, uncomment the following lines:
// import { configureVueProject } from '@vue/eslint-config-typescript'
// configureVueProject({ scriptLangs: ['ts', 'tsx'] })
// More info at https://github.com/vuejs/eslint-config-typescript/#advanced-setup

export default defineConfigWithVueTs(
  {
    name: 'app/files-to-lint',
    files: ['**/*.{vue,ts,mts,tsx}'],
  },

  globalIgnores(['**/dist/**', '**/dist-ssr/**', '**/coverage/**']),

  ...pluginVue.configs['flat/essential'],
  vueTsConfigs.recommended,

  {
    ...pluginVitest.configs.recommended,
    files: ['src/**/__tests__/*'],
  },

  skipFormatting,

  {
    name: 'app/disable-strict-rules',
    rules: {
      '@typescript-eslint/no-explicit-any': 'off', // 允许使用 any
      '@typescript-eslint/no-unused-expressions': 'off', // 允许 a && b() 这种表达式
      '@typescript-eslint/no-unused-vars': 'warn', // 没用到的变量降级为警告，不阻塞运行
      '@typescript-eslint/ban-ts-comment': 'off', //设置 off 之后：ESLint 不再检查你代码里的 // @ts-ignore。你想写多少写多少，它都不会报错
      '@typescript-eslint/no-empty-object-type': 'off', //设置 off 之后：ESLint 允许你继续使用 {} 类型。
      'vue/no-unused-vars': 'off', // 连 vue 的未使用变量警告也关掉
    },
  },
)
