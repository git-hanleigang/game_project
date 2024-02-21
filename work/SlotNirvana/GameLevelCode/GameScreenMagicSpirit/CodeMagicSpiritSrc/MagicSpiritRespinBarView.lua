---
--xcyy
--2018年5月23日
--MagicSpiritRespinBarView.lua

local MagicSpiritRespinBarView = class("MagicSpiritRespinBarView", util_require("base.BaseView"))

MagicSpiritRespinBarView.m_respinCurrtTimes = 0

function MagicSpiritRespinBarView:initUI()
    self:createCsbNode("MagicSpirit_respin_left.csb")
end

function MagicSpiritRespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function()
            -- 显示 freespin count
            self:updateLeftCount(globalData.slotRunData.iReSpinCount, false)
        end,
        ViewEventType.SHOW_RESPIN_SPIN_NUM
    )
end

function MagicSpiritRespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function MagicSpiritRespinBarView:showRespinBar(totalRespin)
    self:updateLeftCount(totalRespin, true)
end

-- 更新 respin 次数
function MagicSpiritRespinBarView:updateLeftCount(respinCount, bstart)
    if self.m_respinCurrtTimes == respinCount then
        return
    end
    self.m_respinCurrtTimes = respinCount
    
    local updateCount = function()
        local timesNode = nil
        for i = 0, 3 do
            timesNode = self:findChild(string.format("MagicSpirit_FREE_CISHU_%d", i))
            if timesNode then
                timesNode:setVisible( i == respinCount )
            end
        end
    end

    --重置时在第10帧 切换数字
    if(3 == respinCount and not bstart)then
        gLobalNoticManager:postNotification("MagicSpirit_playRespinSound", {2})
        
        self:runCsbAction("actionframe")
        local waitNode = cc.Node:create()
        self:addChild(waitNode)

        performWithDelay(waitNode,function(  )
            updateCount()

            waitNode:removeFromParent()
        end,10/60)
    else
        updateCount()
    end
end

return MagicSpiritRespinBarView
