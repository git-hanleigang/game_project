--[[
    卡片收集规则界面  一些玩法说明 --
]]
local BaseCardMenuRule = util_require("GameModule.Card.baseViews.BaseCardMenuRule")
local CardNadoWheelRule = class("CardNadoWheelRule", BaseCardMenuRule)

function CardNadoWheelRule:initDatas()
    CardNadoWheelRule.super.initDatas(self)
    local csbPath = string.format(CardResConfig.seasonRes.CardRuleRes, "season" .. CardSysRuntimeMgr:getCurAlbumID())
    self:setLandscapeCsbName(csbPath)
end

-- 初始化UI --
function CardNadoWheelRule:initUI()
    CardNadoWheelRule.super.initUI(self, true)
    self:runCsbAction("idle")
end

-- function CardNadoWheelRule:getLeftAdaptList()
--     return {self:findChild("Button_6"), self:findChild("layer_left")}
-- end

-- function CardNadoWheelRule:getRightAdaptList()
--     return {self:findChild("Button_4"), self:findChild("Button_7"), self:findChild("layer_right")}
-- end

function CardNadoWheelRule:onEnter()
    CardNadoWheelRule.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            self:closeUI()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

-- function CardNadoWheelRule:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

--适配方案 --
-- function CardNadoWheelRule:getUIScalePro()
--     -- local x = display.width / DESIGN_SIZE.width
--     -- local y = display.height / DESIGN_SIZE.height
--     -- local pro = x / y
--     local pro = BaseCardMenuRule.super.getUIScalePro(self)
--     if globalData.slotRunData.isPortrait == true then
--         -- pro = 0.8

--         local y = display.height * 0.5
--         local layerLeft = self:findChild("layer_left")
--         local layerRight = self:findChild("layer_right")
--         local prePage = self:findChild("Button_6")
--         local nextPage = self:findChild("Button_7")
--         layerLeft:setPositionY(y)
--         layerRight:setPositionY(y)
--         prePage:setPositionY(y)
--         nextPage:setPositionY(y)

--         local exitBtn = self:findChild("Button_4")
--         exitBtn:setPositionY(display.height * 0.7)
--     end
--     return pro
-- end

function CardNadoWheelRule:initShowRuleList()
    self.m_showRuleList = {}

    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if albumId == "202203" then
        self.m_showIndexs = {4, 5, 6}
    else
        self.m_showIndexs = {5, 6}
    end
    for i = 1, #self.m_showIndexs do
        local rule = self:findChild("rule_" .. self.m_showIndexs[i])
        self.m_showRuleList[i] = rule
    end
end

function CardNadoWheelRule:clickExitBtn()
    self:closeUI()
end

return CardNadoWheelRule
