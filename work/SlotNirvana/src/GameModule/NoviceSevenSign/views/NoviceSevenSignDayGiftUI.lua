--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-20 10:28:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-20 10:40:06
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/views/NoviceSevenSignDayGiftUI.lua
Description: 新手期 7日签到V2  礼包
--]]
local NoviceSevenSignDayGiftUI = class("NoviceSevenSignDayGiftUI", BaseView)

function NoviceSevenSignDayGiftUI:initDatas(_dayData)
    NoviceSevenSignDayGiftUI.super.initDatas(self)

    self._dayData = _dayData
    self._day = self._dayData:getDay()
end

function NoviceSevenSignDayGiftUI:getCsbName()
    return "DailyBonusNoviceResV2/csd/node_gift.csb"
end

function NoviceSevenSignDayGiftUI:initUI()
    NoviceSevenSignDayGiftUI.super.initUI(self)

    -- 礼包显隐
    self:updateGiftUI()

    self:runCsbAction("idle")
end

-- 礼包显隐
function NoviceSevenSignDayGiftUI:updateGiftUI()
    for i=1,7 do
        local node = self:findChild("ui_dailybonus_gift" .. i)
        node:setVisible(i == self._day)
    end
end

-- 领奖礼包 飞
function NoviceSevenSignDayGiftUI:playFlyAct(_receiveData)
    local preParent = self:getParent()
    local startPos = self:convertToWorldSpace(cc.p(0, 0))
    local parent = gLobalViewManager.p_ViewLayer
    util_changeNodeParent(gLobalViewManager.p_ViewLayer, self, ViewZorder.ZORDER_UI)
    local mainView = gLobalViewManager:getViewByName("NoviceSevenSignMainLayer")
    if mainView and mainView.m_csbNode then
        mainView:_addBlockMask()
        local refNode = mainView:findChild("root") or mainView.m_csbNode
        self:setScale(refNode:getScale())
    end
    self:move(startPos)

    local endPos = display.center
    local bezier = {}
    bezier[1] = startPos
    bezier[2] = cc.pAdd(startPos, cc.p((endPos.x - startPos.x) * 0.5, 300))
    bezier[3] = endPos
    local time = 33 / 60
    local moveAct = cc.EaseSineIn:create( cc.BezierTo:create(time, bezier) )
    local flyAct = cc.CallFunc:create(function()
        self:runCsbAction("fly")
    end)
    local spawn = cc.Spawn:create(moveAct, flyAct)
    local openAct = cc.CallFunc:create(function()
        self:runCsbAction("open", false, function()
            if tolua.isnull(preParent) then
                return
            end
            util_changeNodeParent(preParent, self, ViewZorder.ZORDER_UI)
            self:move(0, 0)
        end, 60)
    end)
    local delayTime = cc.DelayTime:create((65 - 33)/60)
    local openRewardAct = cc.CallFunc:create(function()
        if not tolua.isnull(mainView) then
            mainView:_removeBlockMask()
        end
        -- 打开领奖弹板
        G_GetMgr(G_REF.NoviceSevenSign):showRewardLayer(_receiveData)
    end)
    local actList = {
        spawn,
        openAct,
        delayTime,
        openRewardAct
    }
    self:runAction(cc.Sequence:create(actList))
end

function NoviceSevenSignDayGiftUI:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_click" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        local refNode = self:findChild("node_qipao")
        local posW = refNode:convertToWorldSpaceAR(cc.p(0, 0))
        local mainView = gLobalViewManager:getViewByName("NoviceSevenSignMainLayer")
        if not mainView then
            return
        end

        mainView:showGiftBubbleView(posW, self._day)
    end
end

return NoviceSevenSignDayGiftUI