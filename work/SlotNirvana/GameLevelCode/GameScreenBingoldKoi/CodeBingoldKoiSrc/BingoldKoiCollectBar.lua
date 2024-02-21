---
--xcyy
--2018年5月23日
--BingoldKoiCollectBar.lua

local BingoldKoiCollectBar = class("BingoldKoiCollectBar",util_require("Levels.BaseLevelDialog"))
BingoldKoiCollectBar.m_lastCount = 0
BingoldKoiCollectBar.m_totalCount = 12

function BingoldKoiCollectBar:initUI(params)

    self.m_machine = params.machine
    self:createCsbNode("BingoldKoi_shouji.csb")

    self:runCsbAction("idle1", true)

    self.m_isLocked = false
    self.m_isExplainClick = true

    self.m_tips = util_createAnimation("BingoldKoi_shoujiTips.csb")
    self:findChild("anniu"):addChild(self.m_tips)
    self.m_tips:setVisible(false)

    self:addClick(self:findChild("Button_1"))

    self.m_collectItems = {}
    self.m_collectImgItems = {}
    for index = 1, self.m_totalCount do
        local item = util_spineCreate("BingoldKoi_shoujiyu",true,true)
        self:findChild("fish_"..index):addChild(item)

        item:setVisible(false)

        self.m_collectItems[#self.m_collectItems + 1] = item

        local collectImg = util_createSprite("BingoldKoiCommon/BingoldKoi_Clooect_fish.png")
        self.m_collectImgItems[#self.m_collectImgItems + 1] = collectImg
        collectImg:setVisible(false)
        self:findChild("fish_"..index):addChild(collectImg)
    end

    self:addClick(self:findChild("Panel_click"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

--默认按钮监听回调
function BingoldKoiCollectBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" or name == "Panel_click" and self.m_isExplainClick then
        if self.m_machine:tipsBtnIsCanClick() then
            if self.m_machine.m_iBetLevel == 0 then
                if globalData.betFlag then
                    self.m_machine.m_bottomUI:changeBetCoinNumToUnLock()
                    self.m_isExplainClick = false
                    self:showTips()
                end
            else
                self.m_isExplainClick = false
                self:showTips()
            end
        end
    end
end

--[[
    刷新收集进度
]]
function BingoldKoiCollectBar:refreshCollectCount(curCount, _onEnter, _callFunc)
    local callFunc = _callFunc
    if curCount < 1 or curCount > self.m_totalCount or self.m_isLocked then
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    if _onEnter then
        for index = 1,#self.m_collectItems do
            -- self.m_collectItems[index]:setVisible(index <= curCount)
            self.m_collectImgItems[index]:setVisible(index <= curCount)
            -- util_spinePlay(self.m_collectItems[index],"idle",true)
            self.m_lastCount = curCount
        end
    else
        if curCount > self.m_lastCount then
            self.m_lastCount = self.m_lastCount + 1
            self.m_collectItems[self.m_lastCount]:setVisible(true)
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Collect_FishFeed)
            util_spinePlay(self.m_collectItems[self.m_lastCount],"actionframe",false)
            util_spineEndCallFunc(self.m_collectItems[self.m_lastCount], "actionframe", function()
                self.m_collectImgItems[self.m_lastCount]:setVisible(true)
                self.m_collectItems[self.m_lastCount]:setVisible(false)
                -- util_spinePlay(self.m_collectItems[self.m_lastCount],"idle",true)
                self:refreshCollectCount(curCount, false, callFunc)
            end)
            if self.m_lastCount == self.m_totalCount then
                self:playTriggerSuper()
            end
        else
            self.m_lastCount = curCount
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    end
end

--[[
    锁定动画(bet不足)
]]
function BingoldKoiCollectBar:lockAni()
    if self.m_isLocked then
        return
    end
    self.m_isLocked = true
    for i=1, self.m_totalCount do
        self.m_collectItems[i]:setVisible(false)
        self.m_collectImgItems[i]:setVisible(false)
    end
    self:runCsbAction("idle", true)
end

--触发动画
function BingoldKoiCollectBar:triggerSuperFree()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle2", true)
    end)
end

function BingoldKoiCollectBar:playTriggerSuper()
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Super_Trigger)
    self:runCsbAction("animation", false)
end

function BingoldKoiCollectBar:playSuperIdle()
    self:runCsbAction("idle2", true)
end

function BingoldKoiCollectBar:playBaseIdle()
    for i=1, self.m_totalCount do
        self.m_collectItems[i]:setVisible(false)
        self.m_collectImgItems[i]:setVisible(false)
    end
    self.m_lastCount = 0
    self:runCsbAction("over", false, function()
        self:runCsbAction("idle1", true)
    end)
end

--[[
    解锁动画
]]
function BingoldKoiCollectBar:unLockAni()
    if not self.m_isLocked then
        return
    end
    self.m_isLocked = false
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Collect_UnLock)
    self:runCsbAction("swith", false, function()
        self:runCsbAction("idle1", true)
    end)
end

function BingoldKoiCollectBar:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function BingoldKoiCollectBar:showTips()
    self.m_tips:stopAllActions()
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            self.m_tips:runCsbAction("over",false, function()
                self.m_isExplainClick = true
                self.m_tips:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self.m_tips:setVisible(true)
        self.m_tips:runCsbAction("start",false, function()
            self.m_isExplainClick = true
            self.m_tips:runCsbAction("idle",true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_tips, function ()
	    closeTips()
    end, 4.0)
end

return BingoldKoiCollectBar