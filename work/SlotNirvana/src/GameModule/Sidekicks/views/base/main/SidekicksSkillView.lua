--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-08 14:51:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-08 14:52:44
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/season/season_1/main/SidekicksSkillView.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksSkillView = class("SidekicksSkillView", BaseView)
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")

function SidekicksSkillView:initDatas(_seasonIdx, _idx, _mainLayer)
    SidekicksSkillView.super.initDatas(self)

    self._data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    self._seasonIdx = _seasonIdx
    self._idx = _idx
    self._mainLayer = _mainLayer
end

function SidekicksSkillView:getCsbName()
    return string.format("Sidekicks_%s/csd/main/Sidekicks_Main_skill_%s.csb", self._seasonIdx, self._idx)
end

function SidekicksSkillView:initCsbNodes()
    SidekicksSkillView.super.initCsbNodes(self)
    
    self._lbAddExNum = self:findChild("lb_skill_" .. self._idx)
end

function SidekicksSkillView:initUI()
    SidekicksSkillView.super.initUI(self)
    self:updateUI()
end

function SidekicksSkillView:updateUI()
    self._petInfoList = self._data:getTotalPetsList()

    -- 加成数值
    self:updateBuffSumUI()
    -- 加成气泡
    self:updateBubbleView()
end

-- 加成数值
function SidekicksSkillView:updateBuffSumUI()
    local keyList = {"FreeEx", "PayEx"}
    local sum = self._data:getTotalSkillNum(keyList[self._idx])
    local str = string.format("+%s%%", sum)
    self._lbAddExNum:setString(str)
end

-- 加成气泡
function SidekicksSkillView:updateBubbleView()
    if self._bubbleView then
        self._bubbleView:updateUI(self._petInfoList)
        return
    end
    local parent = self:findChild("node_bubble")
    local view = util_createView("GameModule.Sidekicks.views.base.main.SidekicksSkillBubbleView", self._seasonIdx, self._idx, self._petInfoList)
    view:addTo(parent)
    view:updateUI(self._petInfoList)
    self._bubbleView = view 
end

function SidekicksSkillView:closebubble()
    self._bubbleView:playHideAct()
end

function SidekicksSkillView:clickFunc(_sender)
    local name = _sender:getName()
    
    if self._bubbleView then
        self._mainLayer:closeSkillbubble()

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self._bubbleView:switchShowState()
    end
end

function SidekicksSkillView:onEnter()
    SidekicksSkillView.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self, "updateUI", SidekicksConfig.EVENT_NAME.NOTICE_UPDATE_SIDEKICKS_DATE) -- 宠物数据更新
end


return SidekicksSkillView