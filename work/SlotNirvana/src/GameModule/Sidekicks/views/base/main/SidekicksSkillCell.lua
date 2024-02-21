--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-11 10:39:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-11 12:23:45
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/season/season_1/main/SidekicksSkillCell.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksSkillCell = class("SidekicksSkillCell", BaseView)

function SidekicksSkillCell:initDatas(_seasonIdx, _idx, _petInfo)
    SidekicksSkillCell.super.initDatas(self)

    self._seasonIdx = _seasonIdx
    self._idx = _idx
    self._petInfo = _petInfo
end

function SidekicksSkillCell:getCsbName()
    return string.format("Sidekicks_%s/csd/main/Sidekicks_Main_skill_bubble_bonus.csb", self._seasonIdx)
end

function SidekicksSkillCell:initUI()
    SidekicksSkillCell.super.initUI(self)
    
    -- 图标
    self:initIconUI()
    self:updateUI(self._petInfo)
end

function SidekicksSkillCell:updateUI(_petInfo)
    self._petInfo = _petInfo
    
    -- 描述显隐
    self:updateDescVisible()
    -- buff数值
    self:updateBuffNumUI()
end

-- 图标
function SidekicksSkillCell:initIconUI()
    local parent = self:findChild("node_head")
    local petId = self._petInfo:getPetId()
    local petHeadResPath = string.format("Sidekicks_Common/pet_head/head_pet_%s.png", petId)
    local sp = util_createSprite(petHeadResPath)
    if sp then
        sp:addTo(parent)
    end
end

-- 描述显隐
function SidekicksSkillCell:updateDescVisible()
    local lbLvDesc = self:findChild("lb_desc")

    local lv = self._petInfo:getLevel()
    local desc = string.format("LV:%s", lv)
    if self._idx == 2 then
        -- 第二个技能显示 星级
        lv = self._petInfo:getStar()
        desc = string.format("STAR:%s", lv)
    end
    lbLvDesc:setString(desc)
end

-- buff数值
function SidekicksSkillCell:updateBuffNumUI()
    local lbBuffNum = self:findChild("lb_bonus_num")
    local cfgInfo = self._petInfo:getSkillInfoById(self._idx) 
    local buffNum = cfgInfo:getCurrentEx()
    lbBuffNum:setString(string.format("+%s%%", buffNum))
end

return SidekicksSkillCell