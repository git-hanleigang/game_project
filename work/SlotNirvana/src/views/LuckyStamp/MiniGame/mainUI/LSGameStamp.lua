--[[
]]
local UIStatus = {
    Stamp = 1,
    Roll = 2
}
local LSGameStamp = class("LSGameStamp", BaseView)

function LSGameStamp:initDatas(_clickBack, _clickRoll)
    self.m_clickBack = _clickBack
    self.m_clickRoll = _clickRoll
    self.m_UIStatus = self:getUIStatus()
end

function LSGameStamp:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_stamp.csb"
end

function LSGameStamp:initCsbNodes()
    self.m_nodeSlots = {}
    for i = 1, 4 do
        local nodeSlot = self:findChild("node_slot" .. i)
        table.insert(self.m_nodeSlots, nodeSlot)
    end
    self.m_nodeStampEffect = self:findChild("node_stamp_effect")
    self.m_btnRoll = self:findChild("btn_start")
    self.m_btnBack = self:findChild("btn_back") --2023
end

function LSGameStamp:initUI()
    LSGameStamp.super.initUI(self)
    self:initUIStatus()
    self:initStamps()
end

function LSGameStamp:switch2Stamp(_over)
    self.m_UIStatus = self:getUIStatus()
    if LuckyStampCfg.TEST_MODE == true then
        self.m_UIStatus = UIStatus.Stamp
    end
    self:updateStamps()
    gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/Switch2Play.mp3")
    self:playChange2Stamp(
        function()
            if not tolua.isnull(self) then
                self:playStampIdle()
                if _over then
                    _over()
                end
            end
        end
    )
end

function LSGameStamp:switch2Roll(_over)
    self.m_UIStatus = self:getUIStatus()
    self:setBtnRollEnabled(true)
    gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/Switch2Play.mp3")
    self:playChange2Roll(
        function()
            if not tolua.isnull(self) then
                self:playRollIdle()
                if _over then
                    _over()
                end
            end
        end
    )
end

function LSGameStamp:initUIStatus()
    if self.m_UIStatus == UIStatus.Stamp then
        self:playStampIdle()
    else
        self:playRollIdle()
        local isDisabled = self:isPlayBtnDisabled()
        self:setBtnRollEnabled(not isDisabled)
    end
end

function LSGameStamp:initStamps()
    self.m_slots = {}
    for i = 1, #self.m_nodeSlots do
        local slot = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameStampSlot", i)
        self.m_nodeSlots[i]:addChild(slot)
        table.insert(self.m_slots, slot)
    end
end

function LSGameStamp:getStampWorldPos(_index)
    if _index and self.m_slots[_index] then
        local slot = self.m_slots[_index]
        local worldPos = slot:getParent():convertToWorldSpace(cc.p(slot:getPosition()))
        return worldPos
    end
    return nil
end

function LSGameStamp:updateStamps()
    for i = 1, #self.m_slots do
        self.m_slots[i]:updateStamp()
    end
end

function LSGameStamp:playStampIdle()
    self:runCsbAction("node_btn1", true, nil, 60)
end

function LSGameStamp:playRollIdle()
    self:runCsbAction("node_btn2", true, nil, 60)
end

function LSGameStamp:playChange2Stamp(_over)
    self:runCsbAction("start2", false, _over, 60)
end

function LSGameStamp:playChange2Roll(_over)
    self:runCsbAction("node_btn2", true, nil, 60) --新版不用原来动画，直接一帧切换按钮就可以
    --self:runCsbAction("start", false, _over, 60)
end

function LSGameStamp:setBtnRollEnabled(_enabled)
    self.m_btnRoll:setBrightStyle(_enabled == true and BRIGHT_NORMAL or BRIGHT_HIGHLIGHT)
    self.m_btnRoll:setTouchEnabled(_enabled)
end

function LSGameStamp:showStampEffect(_index, _type, _over)
    local csb = nil
    if _type == LuckyStampCfg.StampType.Normal then
        csb = LuckyStampCfg.csbPath .. "mainUI/LuckyStamp_gaizhang.csb"
    else
        csb = LuckyStampCfg.csbPath .. "mainUI/LuckyStamp_gaizhang_golden.csb"
    end
    if csb then
        local stampEffect = util_createAnimation(csb)
        self.m_nodeStampEffect:addChild(stampEffect)
        stampEffect:playAction(
            "gaizhang",
            false,
            function()
                if not tolua.isnull(self) then
                    if not tolua.isnull(stampEffect) then
                        stampEffect:removeFromParent()
                        stampEffect = nil
                    end
                    if _over then
                        _over()
                    end
                end
            end,
            30
        )
        local spStamp = self.m_nodeSlots[_index]
        if spStamp then
            stampEffect:setPosition(spStamp:getPosition())
        end
    else
        if _over then
            _over()
        end
    end
end
function LSGameStamp:onEnter()
    LSGameStamp.super.onEnter(self)
end

function LSGameStamp:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_back" then
        if self.m_clickBack then
            self.m_clickBack(true)
        end
    elseif name == "btn_start" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:setBtnRollEnabled(false)
        if self.m_clickRoll then
            self.m_clickRoll()
        end
    end
end

function LSGameStamp:getUIStatus()
    if LuckyStampCfg.TEST_MODE == true then
        return UIStatus.Stamp
    end
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processData = data:getCurProcessData()
        if processData then
            if processData:getIndex() == data:getTotal() then
                return UIStatus.Roll
            end
        end
    end
    return UIStatus.Stamp
end

function LSGameStamp:isPlayBtnDisabled()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local curProcessData = data:getCurProcessData()
        if curProcessData and curProcessData:isHaveGame() == true then
            if curProcessData:isSpin() == true and curProcessData:isCollect() == false then
                return true
            end
        end
    end
    return false
end

return LSGameStamp
