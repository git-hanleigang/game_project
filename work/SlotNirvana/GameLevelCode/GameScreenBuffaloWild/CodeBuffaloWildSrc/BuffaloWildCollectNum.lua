---
--xcyy
--2018年5月23日
--BuffaloWildCollectNum.lua

local BuffaloWildCollectNum = class("BuffaloWildCollectNum",util_require("base.BaseView"))


function BuffaloWildCollectNum:initUI()

    self:createCsbNode("BuffaloWild_bonus_FreeGames_0.csb")

    self:runCsbAction("idle") -- 播放时间线
    self.m_labNum = self:findChild("m_lb_num") -- 获得子节点
    -- self.m_collectNum = 0
end


function BuffaloWildCollectNum:onEnter()
 
end

function BuffaloWildCollectNum:initCollectNum(num)
    self.m_labNum:setString(num)
    -- self.m_collectNum = num
end

function BuffaloWildCollectNum:collect(num)
    -- self.m_collectNum = self.m_collectNum + num
    gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_collect_num.mp3")
    self:runCsbAction("start")
    performWithDelay(self, function()
        self.m_labNum:setString(num)
    end, 0.3)
end

function BuffaloWildCollectNum:onExit()
 
end

function BuffaloWildCollectNum:getCollectPos()
    local node = self:findChild("Buffalo_jinbi_1")
    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return pos
end

return BuffaloWildCollectNum