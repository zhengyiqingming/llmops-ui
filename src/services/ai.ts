import { post, ssePost } from '@/utils/request.ts'
import type { BaseResponse } from '@/models/base.ts'

// 优化预设prompt服务接口
export const optimizePrompt = (
  prompt: string,
  onData: (event_response: Record<string, any>) => void, //onData是回调函数，接受的参数是event_response，类型是一个字典，用Record定义
) => {
  return ssePost(`/ai/optimize-prompt`, { body: { prompt } }, onData)
}

//生成建议问题列表接口
export const generateSuggestedQuestions = (message_id: string) => {
  return post<BaseResponse<string[]>>(`/ai/suggested-questions`, { body: { message_id } })
}
