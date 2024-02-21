
local ColorfulCircusBottomUiView = class("ColorfulCircusBottomUiView",util_require("views.gameviews.GameBottomNode"))

ColorfulCircusBottomUiView.m_isMapWinTimes = false

-- function ColorfulCircusBottomUiView:playCoinWinEffectUI(callBack)
--     local coinBottomEffectNode = self.coinBottomEffectNode
--     if coinBottomEffectNode ~= nil and self.coinBottomEffectAct ~= nil then
--         if not tolua.isnull(self.coinBottomEffectAct) then
--             util_resetCsbAction(self.coinBottomEffectAct)
--         end
        
--         coinBottomEffectNode:setVisible(true)
--         util_csbPlayForKey(
--             self.coinBottomEffectAct,
--             "actionframe",
--             false,
--             function()
--                 coinBottomEffectNode:setVisible(false)
--                 if callBack ~= nil then
--                     callBack()
--                 end
--             end
--         )
--     else
--         if callBack ~= nil then
--             callBack()
--         end
--     end
-- end

function ColorfulCircusBottomUiView:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2

    if self.m_isMapWinTimes then    --地图界面小节点 赢钱时间固定
        return 1
    end

    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 3
    end

    return showTime
end

function ColorfulCircusBottomUiView:setMapWinTime(isMapTime)
    self.m_isMapWinTimes = isMapTime
end

return ColorfulCircusBottomUiView