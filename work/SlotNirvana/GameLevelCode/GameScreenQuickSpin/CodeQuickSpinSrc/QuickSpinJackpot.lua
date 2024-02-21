---
--xcyy
--2018年5月23日
--QuickSpinJackpot.lua

local QuickSpinJackpot = class("QuickSpinJackpot",util_require("base.BaseView"))


function QuickSpinJackpot:initUI()

    self:createCsbNode("QuickSpin_Jackpot.csb")

    self:runCsbAction("animation0", true) -- 播放时间线
    self.m_words = util_createView("CodeQuickSpinSrc.QuickSpinWords")
    self:findChild("words"):addChild(self.m_words) -- 获得子节点
    self.m_words:runAnimation("idle1", true)
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end

function QuickSpinJackpot:playScaleAction(actionName)
    util_playScaleToAction(self.m_words,0.3,0.01,function()
        self:changeWords(actionName)
        util_playScaleToAction(self.m_words,0.3,1,function()

        end)
    end)
end

function QuickSpinJackpot:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    self.m_words:setFreespinNum(leftFsCount)
end

function QuickSpinJackpot:changeWords(type)
    if type == "normal" then
        self.m_words:runAnimation("idle1", true)
    elseif type == "freespin" then
        local leftFsCount = globalData.slotRunData.freeSpinCount
        if leftFsCount == 0 then
            self.m_words:runAnimation("idle4", true)
        elseif leftFsCount == 1 then
            self.m_words:runAnimation("idle3", true)
        else
            self.m_words:runAnimation("idle2", true)
            self:changeFreeSpinByCount()
        end
    elseif type == "wheel1" then
        self.m_words:runAnimation("idle5", true)
    elseif type == "wheel0" then
        self.m_words:runAnimation("idle6", true)
    elseif type == "triggerRespin" then
        self.m_words:runAnimation("idle8", true)
    elseif type == "startRespin" then
        self.m_words:runAnimation("idle7", true)
    end
end

function QuickSpinJackpot:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount()
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function QuickSpinJackpot:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return QuickSpinJackpot