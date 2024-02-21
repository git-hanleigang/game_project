--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local ActivityBetCondition = class("ActivityBetCondition")
ActivityBetCondition.p_activityId = nil --活动id
ActivityBetCondition.p_minLevel = nil --等级范围
ActivityBetCondition.p_maxLevel = nil --等级范围
ActivityBetCondition.p_betGear = nil --bet序号

function ActivityBetCondition:ctor()
    
end

function ActivityBetCondition:parseData(data)
      self.p_activityId = data.activityId
      self.p_minLevel = data.minLevel
      self.p_maxLevel = data.maxLevel
      self.p_betGear = data.betGear

end

return  ActivityBetCondition