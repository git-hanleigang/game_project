---
--xcyy
--2018年5月29日
--LightCherryRespinBarItem.lua

local LightCherryRespinBarItem = class("LightCherryRespinBarItem", util_require("base.BaseView"))

function LightCherryRespinBarItem:initUI()
    -- TODO 输入自己初始化逻辑
    self:createCsbNode("LightCherry_respin_bar_item.csb")
end

--[[
    变更最大次数显示
]]
function LightCherryRespinBarItem:changeMaxCountShow(count)
    self.m_maxCount = count
    self:findChild("Node_3"):setVisible(count == 3)
    self:findChild("Node_4"):setVisible(count == 4)
    self:findChild("Node_5"):setVisible(count == 5)
end

--[[
    刷新当前次数显示
]]
function LightCherryRespinBarItem:updateCurCount(count,isInit)
    self.m_curCount = count
    for index = 1,self.m_maxCount do
        local highLightNode = self:findChild("sp_high_light_"..self.m_maxCount.."_"..index)
        if highLightNode then
            highLightNode:setVisible(index == count)
        end
    end

    if count == self.m_maxCount then
        self:runCsbAction("fankui")
    end
    
end

return LightCherryRespinBarItem