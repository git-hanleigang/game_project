---
--xcyy
--2018年5月23日
--WolfSmashWolfTipsView.lua

local WolfSmashWolfTipsView = class("WolfSmashWolfTipsView",util_require("Levels.BaseLevelDialog"))

local POINT_POS = {
    UP = 1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4,
}

local leftShow = {1,2,3,14,15,29,30,31,42,43,57,58,59,70,71}
local downShow = {4,5,6,7,11,12,13,16,17,18,19,20,21,25,26,27,28,32,33,34,35,39,40,41,44,45,46,47,48,
49,53,54,55,56,60,61,62,63,67,68,69,72,73,74,75,76,77,81,82}
local rightShow = {8,9,10,22,23,24,36,37,38,50,51,52,64,65,66,78,79,80}

function WolfSmashWolfTipsView:initUI()

    self:createCsbNode("WolfSmash_jiaobiao_lang.csb")

    self.wolfJveSe = util_spineCreate("Socre_WolfSmash_juese",true,true)
    self:findChild("juese"):addChild(self.wolfJveSe)

    self.curPosIndex = 0

end

function WolfSmashWolfTipsView:initPointPos(index)
    local pos = self:getPosIndex(index)
    self.curPosIndex = pos
    if pos == POINT_POS.DOWN then
        
        util_spinePlay(self.wolfJveSe, "idle_zuo", true)
        self:runCsbAction("idle2",true)
    elseif pos == POINT_POS.LEFT then
        util_spinePlay(self.wolfJveSe, "idle_zuo", true)
        self:runCsbAction("idle1",true)
    elseif pos == POINT_POS.RIGHT then
        util_spinePlay(self.wolfJveSe, "idle_you", true)
        self:runCsbAction("idle3",true)
    else
        util_spinePlay(self.wolfJveSe, "idle_zuo", true)
        self:runCsbAction("idle1",true)
    end
end

function WolfSmashWolfTipsView:changePointPos(oldPosindex,newPosindex)
    local oldPos = self:getPosIndex(oldPosindex)
    local newPos = self:getPosIndex(newPosindex)
    self.curPosIndex = newPos
    if oldPos == newPos then
        return
    end
    
    if oldPos == POINT_POS.DOWN and newPos == POINT_POS.LEFT then
        self:runCsbAction("xia_zuo",false,function ()
            util_spinePlay(self.wolfJveSe, "idle_zuo", true)
            self:runCsbAction("idle1",true)
        end)
    elseif oldPos == POINT_POS.LEFT and newPos == POINT_POS.DOWN then
        self:runCsbAction("zuo_xia",false,function ()
            util_spinePlay(self.wolfJveSe, "idle_zuo", true)
            self:runCsbAction("idle2",true)
        end)
    elseif oldPos == POINT_POS.RIGHT and newPos == POINT_POS.DOWN then
        self:runCsbAction("you_xia",false,function ()
            util_spinePlay(self.wolfJveSe, "idle_zuo", true)
            self:runCsbAction("idle2",true)
        end)
    elseif oldPos == POINT_POS.DOWN and newPos == POINT_POS.RIGHT then
        self:runCsbAction("xia_you",false,function ()
            util_spinePlay(self.wolfJveSe, "idle_you", true)
            self:runCsbAction("idle3",true)
        end)
    end
end

function WolfSmashWolfTipsView:getPosIndex(index)
    for i,v in ipairs(leftShow) do
        if v == index then
            return POINT_POS.LEFT
        end
    end
    for i,v in ipairs(downShow) do
        if v == index then
            return POINT_POS.DOWN
        end
    end
    for i,v in ipairs(rightShow) do
        if v == index then
            return POINT_POS.RIGHT
        end
    end
end

function WolfSmashWolfTipsView:showSmash()
    if self.curPosIndex == POINT_POS.DOWN then
        util_spinePlay(self.wolfJveSe, "jida_xia", false)
        util_spineEndCallFunc(self.wolfJveSe, "jida_xia", function()
            util_spinePlay(self.wolfJveSe, "idle_zuo", true)
        end)
    elseif self.curPosIndex == POINT_POS.LEFT then
        util_spinePlay(self.wolfJveSe, "jida_zuo", false)
        util_spineEndCallFunc(self.wolfJveSe, "jida_zuo", function()
            util_spinePlay(self.wolfJveSe, "idle_zuo", true)
        end)
    elseif self.curPosIndex == POINT_POS.RIGHT then
        util_spinePlay(self.wolfJveSe, "jida_you", false)
        util_spineEndCallFunc(self.wolfJveSe, "jida_you", function()
            util_spinePlay(self.wolfJveSe, "idle_you", true)
        end)
    end
end


return WolfSmashWolfTipsView