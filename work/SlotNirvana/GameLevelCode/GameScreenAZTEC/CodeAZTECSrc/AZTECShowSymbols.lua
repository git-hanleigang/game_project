---
--xcyy
--2018年5月23日
--AZTECShowSymbols.lua

local AZTECShowSymbols = class("AZTECShowSymbols",util_require("base.BaseView"))


function AZTECShowSymbols:initUI(data)

    self:createCsbNode("AZTEC_bet_paytable.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self.m_machine = data
    if globalData.slotRunData.isDeluexeClub == true then
        local btn = self:findChild("Button")
        btn:setBright(false)
        btn:setTouchEnabled(false)
    end
end

function AZTECShowSymbols:updateByBetLevel(level)
    self:runCsbAction("idle"..level)
end

function AZTECShowSymbols:onEnter()
    if globalData.slotRunData.isDeluexeClub ~= true then
        gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
            self:updateBetEnable(params)
        end,"BET_ENABLE")
    end
end

function AZTECShowSymbols:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function AZTECShowSymbols:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_machine:chooseBetLayer()
end

function AZTECShowSymbols:updateBetEnable(flag)
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        flag=false
    end
    local btn = self:findChild("Button")
    btn:setBright(flag)
    btn:setTouchEnabled(flag)
end

return AZTECShowSymbols