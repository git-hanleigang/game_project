-- 主界面 增倍器进度条

local CashBonusMutiBar = class("CashBonusMutiBar", util_require("base.BaseView"))

local TTF_COLOR_NORMAL = {
    text = cc.c4b(255, 255, 255, 255), -- 白
    outLine = cc.c4b(53, 2, 55, 255), 
    outLineSize = 3
}
local TTF_COLOR_FINISH = {
    text = cc.c4b(255, 255, 255, 255), -- 黄
    outLine = cc.c4b(190, 76, 0, 255), 
    outLineSize = 3
}
function CashBonusMutiBar:initUI()
    -- setDefaultTextureType("RGBA8888", nil)

    self:createCsbNode("NewCashBonus/CashBonusNew/CashBonus_multBaR.csb")
    self:initBarData()
    -- setDefaultTextureType("RGBA4444", nil)
end

function CashBonusMutiBar:initBarData()
    -- 增倍器 完成对应阶段增长的进度
    -- 这里需要与工程里面的进度条对应上
    local rates = {
        20,
        40,
        60,
        80,
        100
    }
    -- 初始化增倍器倍数信息
    local curData = G_GetMgr(G_REF.CashBonus):getMultipleData()
    local allMultList = G_GetMgr(G_REF.CashBonus):getAllMultipleData()
    local percent = 0
    local aveRate = 100 * #allMultList
    for i = 1, #allMultList do
        local checkMultData = allMultList[i]
        local multLight = self:findChild("multLight"..i)
        multLight:setString("X" .. checkMultData.p_value)
        if checkMultData.p_value < curData.p_value then
            percent = rates[i]
            multLight:enableOutline(TTF_COLOR_FINISH.outLine, TTF_COLOR_FINISH.outLineSize)
            multLight:setTextColor(TTF_COLOR_FINISH.text)
        elseif checkMultData.p_value == curData.p_value then

            if checkMultData.p_value == allMultList[#allMultList].p_value then
                percent = rates[#rates]
            else
                local pre_percent = rates[i - 1] or 0
                local cur_percent = rates[i]
                percent = percent + curData.p_exp / curData.p_maxExp * (cur_percent - pre_percent)
            end
    
            multLight:enableOutline(TTF_COLOR_FINISH.outLine, TTF_COLOR_FINISH.outLineSize)
            multLight:setTextColor(TTF_COLOR_FINISH.text)
        end
    end
    local height = (percent / 100) *500
    self:findChild("ef_jindutiao"):setContentSize(cc.size(86,height))
    self:findChild("LoadingBar_1"):setPercent(percent)
end

function CashBonusMutiBar:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function()
            self:initBarData()
        end,
        ViewEventType.CASHBONUS_UPDATE_MULTIPLE
    )
end

return CashBonusMutiBar
