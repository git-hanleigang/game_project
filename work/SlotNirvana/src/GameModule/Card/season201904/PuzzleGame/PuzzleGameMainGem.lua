--[[--
    小游戏 - 宝石
]]
local BaseView = util_require("base.BaseView")
local PuzzleGameMainGem = class("PuzzleGameMainGem", BaseView)
function PuzzleGameMainGem:initUI()
    self:createCsbNode(CardResConfig.PuzzleGameMainGemRes)

    self.m_numLB = self:findChild("lb_gemNum")
    self.m_btnPlus = self:findChild("btn_plus")
    self.m_panelBG = self:findChild("Panel_bg")
    self:addClick(self.m_panelBG)
end

function PuzzleGameMainGem:onEnter()
    self:closeTimeSchedule()
    -- self.m_timeSchedule = schedule(
    --     self,
    --     function()
    --         local data = CardSysRuntimeMgr:getPuzzleGameData()
    --         local leftTime = 0
    --         if data then
    --             leftTime = math.max(0, util_getLeftTime(data.coolDown))
    --         end

    --         if leftTime == 0 then
    --             self:closeTimeSchedule()
    --         end
            
    --         if leftTime < (30*60) then
    --             self.m_btnPlus:setVisible(false)
    --         end
    --     end,
    --     1
    -- )
end

function PuzzleGameMainGem:onExit( )
    gLobalNoticManager:removeAllObservers(self)
end

function PuzzleGameMainGem:closeTimeSchedule()
    if self.m_timeSchedule ~= nil then
        self:stopAction(self.m_timeSchedule)
        self.m_timeSchedule = nil
    end    
end

function PuzzleGameMainGem:updateUI()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    self.m_numLB:setString(data.cardRuby)

    -- local leftTime = 0
    -- if data then
    --     leftTime = math.max(0, util_getLeftTime(data.coolDown))
    -- end

    -- if leftTime < (30 * 60) then
    --     self.m_btnPlus:setVisible(false)
    -- end
end


function PuzzleGameMainGem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_plus" or name == "Panel_bg" then
        gLobalSendDataManager:getLogIap():setEntryName("btn_plus")
        self:openShop()
    end
end

function PuzzleGameMainGem:openShop()
    -- 进入商城
    local view = G_GetMgr(G_REF.Shop):showMainLayer()
    view.buyShop = true

    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_JUMP_TO_SHOP)
    -- 退出卡牌系统
    -- CardSysManager:exitCard()
end

return PuzzleGameMainGem
