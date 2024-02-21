--[[
    -- 集卡在关卡中升级时的引导
    author:{author}
    time:2019-10-24 14:55:48
]]
local CardDropGuide = class("CardDropGuide", BaseLayer)

function CardDropGuide:initDatas(exitFunc, showMeFunc)
    -- 点击X按钮的回调
    self.m_exitFunc = exitFunc
    self.m_showMeFunc = showMeFunc

    self.ActionType = "Common"
    self:setLandscapeCsbName("unlockDailyTask/unlockCardCollect.csb")
end

function CardDropGuide:initUI(exitFunc, showMeFunc)
    CardDropGuide.super.initUI(self)
    self:runCsbAction("idle")
    -- local isAutoScale = true
    -- if CC_RESOLUTION_RATIO == 3 then
    --     isAutoScale = false
    -- end
    -- self:createCsbNode(CardResConfig.CardDropGuideRes, isAutoScale)
    -- self:createCsbNode("unlockDailyTask/unlockCardCollect.csb", isAutoScale)

    -- local root = self:findChild("root")
    -- if root then
    --     self:runCsbAction("idle")
    --     self:commonShow(
    --         root,
    --         function()
    --             self:runCsbAction("idle", true, nil, 60)
    --         end
    --     )
    -- else
    --     self:runCsbAction(
    --         "start",
    --         false,
    --         function()
    --             self:runCsbAction("idle", true, nil, 60)
    --         end,
    --         60
    --     )
    -- end
end

function CardDropGuide:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

--适配方案
-- function CardDropGuide:getUIScalePro()
--     local x = display.width / DESIGN_SIZE.width
--     local y = display.height / DESIGN_SIZE.height
--     local pro = x / y
--     if globalData.slotRunData.isPortrait == true then
--         pro = 0.75
--     end
--     return pro
-- end

function CardDropGuide:closeUI(closeType)
    if self.isClose then
        return
    end
    self.isClose = true

    local callback = function()
        if closeType == 1 then
            if self.m_exitFunc then
                self.m_exitFunc()
            end
        elseif closeType == 2 then
            if self.m_showMeFunc then
                self.m_showMeFunc()
            end
        end
    end

    CardDropGuide.super.closeUI(self, callback)
end

function CardDropGuide:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        -- 清除打点后续逻辑
        if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
            gLobalSendDataManager:getLogGuide():cleanParams(8)
        end
        CardSysManager:closeDropCardGuide(1)
    elseif name == "btn_show" then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_JumpCard)
        end

        -- 引导打点：Card引导-2.点击showme
        if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(8, 2)
        end

        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        CardSysManager:closeDropCardGuide(2)
    end
end

return CardDropGuide
