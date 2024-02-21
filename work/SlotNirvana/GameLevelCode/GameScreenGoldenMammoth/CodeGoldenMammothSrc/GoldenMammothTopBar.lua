---
--xcyy
--2018年5月23日
--GoldenMammothTopBar.lua

local GoldenMammothTopBar = class("GoldenMammothTopBar",util_require("base.BaseView"))

GoldenMammothTopBar.m_labCount = nil
GoldenMammothTopBar.m_vecSymbol = nil
GoldenMammothTopBar.m_currSymbol = nil
GoldenMammothTopBar.m_bIsAllChange = nil
function GoldenMammothTopBar:initUI()

    self:createCsbNode("GoldenMammoth_topbar.csb")
    self.m_labCount = self:findChild("lab_count")
    self.m_vecSymbol = {}
    local index = 1
    while true do
        local symbol = self:findChild("symbol_" .. index )
        if symbol ~= nil then
            self.m_vecSymbol[index] = symbol
            symbol:setVisible(false)
        else
            break
        end
        index = index + 1
    end
    self.m_bIsAllChange = false
    self.m_currSymbol = 4
    self.m_vecSymbol[self.m_currSymbol]:setVisible(true)
    self:addClick(self:findChild("unlock_btn"))
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
end

function GoldenMammothTopBar:initCountAndSymbol(count, symbol)
    self.m_vecSymbol[self.m_currSymbol]:setVisible(false)
        self.m_currSymbol = symbol
        self.m_vecSymbol[self.m_currSymbol]:setVisible(true)
    self.m_currSymbol = symbol
end

function GoldenMammothTopBar:onEnter()
 

end

function GoldenMammothTopBar:onExit()
 
end

function GoldenMammothTopBar:normal2Freespin()
    local animation = "nomal_freespin"
    self:runCsbAction(animation, false, function()
        self:runCsbAction("idle2", true)
    end)
end

function GoldenMammothTopBar:freespin2Normal()
    if self.m_bIsAllChange == true then
        self:runCsbAction("freespin1_normal")
    else
        self:runCsbAction("freespin_normal")
    end
    self.m_bIsAllChange = false
end

function GoldenMammothTopBar:updateCountAndSymbol(count, symbol, isAnimation)
    if symbol ~= self.m_currSymbol then
        self.m_vecSymbol[self.m_currSymbol]:setVisible(false)
        self.m_currSymbol = symbol
        self.m_vecSymbol[self.m_currSymbol]:setVisible(true)

        local effect, act = util_csbCreate("GoldenMammoth_baodian.csb")
        self.m_vecSymbol[self.m_currSymbol]:getParent():addChild(effect, 10000)
        effect:setPosition(self.m_vecSymbol[self.m_currSymbol]:getPosition())
        util_csbPlayForKey(act, "show", false, function ()
            effect:removeFromParent(true)
        end)
    end
    if isAnimation == true then
        local effect, act = util_csbCreate("GoldenMammoth_baodian.csb")
        self.m_labCount:addChild(effect, 10000)
        effect:setPosition(19, 22)
        util_csbPlayForKey(act, "show", false, function ()
            effect:removeFromParent(true)
        end)
    end
    gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_top_num_change.mp3")
    self.m_labCount:setString(count)
    if count == 0 and symbol == 4 and self.m_bIsAllChange == false then
        self.m_bIsAllChange = true
        self:runCsbAction("freespin_freespin1", false, function()
            self:runCsbAction("idle3", true)
        end)
    end
end

function GoldenMammothTopBar:clickFunc(sender)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end

return GoldenMammothTopBar