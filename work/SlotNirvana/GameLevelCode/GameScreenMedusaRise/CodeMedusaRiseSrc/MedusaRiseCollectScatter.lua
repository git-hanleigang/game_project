---
--xcyy
--2018年5月23日
--MedusaRiseCollectScatter.lua

local MedusaRiseCollectScatter = class("MedusaRiseCollectScatter",util_require("base.BaseView"))

MedusaRiseCollectScatter.m_iFlyScatterNum = nil
MedusaRiseCollectScatter.m_iAnimScatterNum = nil
MedusaRiseCollectScatter.m_iFsTimes = nil

function MedusaRiseCollectScatter:initUI()

    self:createCsbNode("MedusaRise_fs_cishu.csb")

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
    self.m_vecScatters = {}
    local index = 1
    while true do
        local parent = self:findChild("parent"..index)
        if parent ~= nil then
            local scratter = util_createView("CodeMedusaRiseSrc.MedusaRiseScatterItem")
            parent:addChild(scratter)
            self.m_vecScatters[#self.m_vecScatters + 1] = scratter
            util_setCascadeOpacityEnabledRescursion(scratter, true)
        else
            break
        end
        index = index + 1
    end

    self.m_lastEndNode = self:findChild("Node_3")
    self.m_labFsTimes = self:findChild("BitmapFontLabel_1")

    self.m_iFlyScatterNum = 0
    self.m_iAnimScatterNum = 0

end

function MedusaRiseCollectScatter:idleAnim(scatterNum, fsNum)
    self.m_iAnimScatterNum = scatterNum
    self.m_iFlyScatterNum = scatterNum
    local animName = "idle"
    if self.m_iAnimScatterNum >= 3 then
        animName = "idle1"
        self.m_labFsTimes:setString(fsNum)
        self.m_iFsTimes = fsNum
    else
        for i = 1, self.m_iAnimScatterNum, 1 do
            self.m_vecScatters[i]:showIdleframe()
        end
    end
    self:runCsbAction(animName)
end

function MedusaRiseCollectScatter:onEnter()
 
end

function MedusaRiseCollectScatter:onExit()
 
end

function MedusaRiseCollectScatter:showAnim()
    self:runCsbAction("show")
end

function MedusaRiseCollectScatter:hideAnim(func)
    local animName = "over"
    if self.m_iAnimScatterNum >= 3 then
        animName = "over1"
    end
    self:runCsbAction(animName, false, function()
        self:resetUI()
        if func ~= nil then
            func()
        end
    end)
end

function MedusaRiseCollectScatter:showCollectAnim(num)
    self.m_iAnimScatterNum = self.m_iAnimScatterNum + 1
    if self.m_iAnimScatterNum <= 3 then
        local node = self.m_vecScatters[self.m_iAnimScatterNum]
        node:showAnimation(function()
            if self.m_iAnimScatterNum >= 3 then
                self.m_labFsTimes:setString(num)
                
                gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_collect_change.mp3")
                self:runCsbAction("change")
                self.m_iFsTimes = 10 + (self.m_iAnimScatterNum - 3) * 2
                self.m_labFsTimes:setString(self.m_iFsTimes)
                
            end
        end)
    else
        if self.m_iFsTimes ~= nil then
            self.m_iFsTimes = self.m_iFsTimes + 2
            self:runCsbAction("collect")
            self.m_labFsTimes:setString(self.m_iFsTimes)
        end
    end
end

--默认按钮监听回调
function MedusaRiseCollectScatter:getEndPos()
    self.m_iFlyScatterNum = self.m_iFlyScatterNum + 1
    local index = self.m_iFlyScatterNum
    local node = nil
    if index > 3 then
        node = self.m_lastEndNode
    else
        node = self.m_vecScatters[index]
    end
    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return pos
end

function MedusaRiseCollectScatter:resetUI()
    self.m_iFlyScatterNum = 0
    self.m_iAnimScatterNum = 0
    for i = 1, #self.m_vecScatters, 1 do
        self.m_vecScatters[i]:showStart()
    end
end

return MedusaRiseCollectScatter