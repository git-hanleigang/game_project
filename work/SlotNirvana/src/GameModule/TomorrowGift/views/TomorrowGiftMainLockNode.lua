--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 16:09:54
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:20:08
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/views/TomorrowGiftMainLockNode.lua
Description: 次日礼物主界面 锁时间 UI
--]]
local TomorrowGiftMainLockNode = class("TomorrowGiftMainLockNode", BaseView)

function TomorrowGiftMainLockNode:initCsbNodes()
    TomorrowGiftMainLockNode.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function TomorrowGiftMainLockNode:getCsbName()
    return "Activity/TomorrowGift/csb/TomorrowGift_MainLayer_suo.csb"
end

function TomorrowGiftMainLockNode:initUI(_mainView)
    TomorrowGiftMainLockNode.super.initUI(self)
    self._mainView = _mainView
    self.m_data = G_GetMgr(G_REF.TomorrowGift):getRunningData()
    self.m_bUnlock = self.m_data:checkIsUnlock()
    self.m_unlockTime = self.m_data:getUnlockTime()
    self:updateTimeLbUI()
    if not self.m_bUnlock then
        schedule(self.m_lbTime, util_node_handler(self, self.updateTimeLbUI), 1)
    end
    self:runCsbAction("idle")
end

-- 倒计时
function TomorrowGiftMainLockNode:updateTimeLbUI()
    local timeStr, bOver = util_daysdemaining(self.m_unlockTime, true)
    self.m_lbTime:setString(timeStr)

    if bOver then
        self:unlockGiftBenefit()
        self.m_lbTime:stopAllActions()
        return
    end
end

-- 解锁 礼包权益
function TomorrowGiftMainLockNode:unlockGiftBenefit()
    if self.m_bUnlock then
        -- 本来就解锁 打开界面 后播动画
        performWithDelay(self,function()
            self._mainView:unlockGiftBenefit()
        end, 0.3)
        return
    end
    self._mainView:unlockGiftBenefit()
end

-- 播放解锁动画
function TomorrowGiftMainLockNode:playUnlockAni()
    self:runCsbAction("start")
end

return TomorrowGiftMainLockNode