-- 等级里程碑进度界面
local LevelRoadRewardWordNode = class("LevelRoadRewardWordNode", util_require("base.BaseView"))

function LevelRoadRewardWordNode:initUI()
    LevelRoadRewardWordNode.super.initUI(self)
    self:initView()
end

-- _word:"a|b|c|..."
function LevelRoadRewardWordNode:initDatas(_word)
    self.m_word = _word or ""
end

function LevelRoadRewardWordNode:getCsbName()
    return "LevelRoad/csd/LevelRoad_levelbar_reward_bubble_word.csb"
end

function LevelRoadRewardWordNode:initCsbNodes()
    self.m_lb_activity_name = self:findChild("lb_activity_name")
end

function LevelRoadRewardWordNode:initView()
    local word = ""
    local strs = string.split(self.m_word, "|")
    for i = 1, #strs do
        if i == 1 then
            word = word .. strs[i]
        else
            word = word .. "\n" .. strs[i]
        end
    end
    self.m_lb_activity_name:setString(word)
end

return LevelRoadRewardWordNode
