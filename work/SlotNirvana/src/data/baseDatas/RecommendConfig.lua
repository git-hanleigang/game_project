--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local RecommendConfig = class("RecommendConfig")
RecommendConfig.p_id = nil                --关卡id
RecommendConfig.p_name = nil              --关卡名称
RecommendConfig.p_pushSwitch = nil        --推送开关
RecommendConfig.p_slideSwitch = nil       --轮播开关
RecommendConfig.p_hallSwitch = nil        --大厅展示开关

--推荐关卡数据表
function RecommendConfig:ctor()
    
end

function RecommendConfig:parseData(data)
      self.p_id = data.id
      self.p_name = data.name
      self.p_pushSwitch = data.pushSwitch
      self.p_slideSwitch = data.slideSwitch
      self.p_hallSwitch = data.hallSwitch

end

return  RecommendConfig