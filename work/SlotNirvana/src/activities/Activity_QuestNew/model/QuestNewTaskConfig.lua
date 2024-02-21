--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local QuestNewTaskConfig = class("QuestNewTaskConfig")
QuestNewTaskConfig.p_id = nil                      --任务 id
QuestNewTaskConfig.p_type = nil                    --任务类型
QuestNewTaskConfig.p_description = nil             --任务描述
QuestNewTaskConfig.p_params = nil                  --任务参数
QuestNewTaskConfig.p_process = nil                 --任务进度
QuestNewTaskConfig.p_completed = nil               --是否完成

function QuestNewTaskConfig:ctor()
    
end

function QuestNewTaskConfig:parseData(data)
      self.p_id = tonumber(data.id)
      self.p_type = data.type
      self.p_description = data.description
      if data.params ~= nil and #data.params > 0 then
            self.p_params = {}
            for i=1,#data.params do
                  local cell = tonumber(data.params[i])
                  self.p_params[#self.p_params+1] = cell
            end
      end

      if data.process ~= nil and #data.process > 0 then
            self.p_process = {}
            for i=1,#data.process do
                  local cell = tonumber(data.process[i])
                  self.p_process[#self.p_process+1] = cell
            end
      end
      
      self.p_completed = data.completed
      self.p_gems = tonumber(data.gems)
      self.p_stars = tonumber(data.stars) --fantasyQuest 星星
      
end

function QuestNewTaskConfig:getStars()
    return self.p_stars or 0
end

return  QuestNewTaskConfig