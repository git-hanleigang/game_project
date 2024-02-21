--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-12 15:59:51
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-12 16:10:25
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/season/season_1/message/SidekicksSkillMessageView.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE

--]]

local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksSkillMessageView = class("SidekicksSkillMessageView", BaseView)

function SidekicksSkillMessageView:initDatas(_seasonIdx, _idx)
    SidekicksSkillMessageView.super.initDatas(self)

    self._seasonIdx = _seasonIdx
    self._idx = _idx
    self._curNum = 0
    self._curParam = 0
    self._curRate = 0
end

function SidekicksSkillMessageView:getCsbName()
    return string.format("Sidekicks_%s/csd/message/Sidekicks_Message_skill_%s.csb", self._seasonIdx, self._idx)
end

function SidekicksSkillMessageView:initCsbNodes()
    self.m_shengji_lizi = self:findChild("shengji_lizi")
    self.m_shengji_lizi:setVisible(false)

    self.m_lb_next_num = self:findChild("lb_next_num")
    self.m_num_pos = cc.p(self.m_lb_next_num:getPosition())
end

function SidekicksSkillMessageView:updateUI(_petInfo, _curStage, _up)
    self._petInfo = _petInfo
    self._curStage = _curStage
    self._skillInfo = self._petInfo:getSkillInfoById(self._idx)

    -- 加成数值
    if self._idx == 3 then
        self:updateSpecialBuffUI(_up)
    else
        self:updateNormalBuffUI(_up)
    end
end

-- buff数值
function SidekicksSkillMessageView:updateNormalBuffUI(_up)
    -- 当前等级 信息
    local num = self._skillInfo:getCurrentEx()
    local lbBuffNum = self:findChild("lb_base_num")
    local str = num == 0 and "BASE" or string.format("+%s%%", num)
    lbBuffNum:setString(str)

    local info = SidekicksConfig.PET_SKILL_INFO[self._petInfo:getPetId()]
    local skillInfo = info[self._idx]

    -- 下一阶段宠物信息
    local lbNextDesc = self:findChild("lb_next_desc")
    local lbNextNum = self:findChild("lb_next_num")
    lbNextNum:setPosition(self.m_num_pos)
    
    local desc = ""
    local strNum = "MAX"
    -- 最大加成
    local bounsMax = self:curBounsIsMax()
    if bounsMax then
        lbNextDesc:setString(desc)
        lbNextNum:setString(strNum)
        lbNextNum:setPositionX(lbNextNum:getPositionX() + skillInfo.offsetX)
        return
    end

    local curLv = self._petInfo:getLevel()
    local curStar = self._petInfo:getStar()
    local nextLv = self._skillInfo:getNextLevel()
    local nextStar = self._skillInfo:getNextStar()

    if skillInfo.type == "level" and nextLv > curLv then
        desc = "NEXT LEVEL: "
        local nextEx = self._skillInfo:getNextEx()
        strNum = string.format("%s%%", nextEx)
    elseif skillInfo.type == "star" and nextStar > curStar then
        desc = "NEXT STAR: "
        local nextEx = self._skillInfo:getNextEx()
        strNum = string.format("%s%%", nextEx)
    end

    lbNextDesc:setString(desc)
    lbNextNum:setString(strNum)
    
    if _up and self._curNum < num then
        self.m_shengji_lizi:setVisible(true)
        self.m_shengji_lizi:resetSystem()
        local sound = string.format("Sidekicks_%s/sound/Sidekicks_skillUp.mp3", self._seasonIdx)
        gLobalSoundManager:playSound(sound)
    end

    if strNum == "MAX" then
        lbNextNum:setPositionX(lbNextNum:getPositionX() + skillInfo.offsetX)
    end

    self._curNum = num
end

function SidekicksSkillMessageView:updateSpecialBuffUI(_up)
    -- 当前等级 信息
    local curParam = self._skillInfo:getCurrentSpecialParam()
    local curRate = self._skillInfo:getCurrentSpecialRate()
    local lb_base_rate = self:findChild("lb_base_rate")    -- 概率
    local lb_base_bonus = self:findChild("lb_base_bonus")    -- 加成
    local node_base = self:findChild("node_base")
    local lb_lock = self:findChild("lb_lock")
    if curParam <= 0 and curRate <= 0 then
        node_base:setVisible(false)
        lb_lock:setVisible(true)
    else
        node_base:setVisible(true)
        lb_lock:setVisible(false)
        local strParam = string.format("+%s%%", curParam*100)
        local strRate = string.format("%s%%", curRate*100)
        lb_base_rate:setString(strRate)
        lb_base_bonus:setString(strParam)
    end

    local info = SidekicksConfig.PET_SKILL_INFO[self._petInfo:getPetId()]
    local skillInfo = info[self._idx]

    -- 加成图标
    local sp_bigWin = self:findChild("sp_bigWin")
    local sp_extraBet = self:findChild("sp_extraBet")
    sp_bigWin:setVisible(skillInfo.bonus == "bigWin")
    sp_extraBet:setVisible(skillInfo.bonus == "extraBet")

    -- 下一阶段宠物信息
    local lbNextNum = self:findChild("lb_next_num")
    lbNextNum:setPosition(self.m_num_pos)

    local desc = "MAX"
    -- 最大加成
    local bounsMax = self:curBounsIsMax()
    if not bounsMax then
        local curLv = self._petInfo:getLevel()
        local curStar = self._petInfo:getStar()
        local nextLv = self._skillInfo:getNextLevel()
        local nextStar = self._skillInfo:getNextStar()
    
        if nextStar > curStar then
            desc = string.format("%s-STAR: ", nextStar)
        elseif nextLv > curLv then
            desc = string.format("LV:%s: ", nextLv)
        end
    end


    if desc == "MAX" then
        lbNextNum:setString(desc)
        lbNextNum:setPositionX(lbNextNum:getPositionX() + skillInfo.offsetX)
        return
    end

    local nextParam = self._skillInfo:getNextSpecialParam()
    local nextRate = self._skillInfo:getNextSpecialRate()
    desc = desc .. (string.format("RATE %s%%, BONUS %s%%", nextRate*100, nextParam*100))
    lbNextNum:setString(desc)
    
    if _up and (self._curRate < curRate or self._curParam < curParam) then
        self.m_shengji_lizi:setVisible(true)
        self.m_shengji_lizi:resetSystem()
    end

    self._curRate = curRate
    self._curParam = curParam
end

function SidekicksSkillMessageView:curBounsIsMax()
    local flag = false
    local info = self._petInfo:getSkillInfoById(self._idx)
    local nextStage = info:getNextStage()
    local nextSeason = info:getNextSeason()
    if nextStage == 0 then
        flag = true
    end

    return flag
end

function SidekicksSkillMessageView:clickFunc(_sender)
    G_GetMgr(G_REF.Sidekicks):showRuleLayer(self._seasonIdx, self._idx)
end

return SidekicksSkillMessageView