--[[
    戳+槽
]]
local LSGameStampSlot = class("LSGameStampSlot", BaseView)

function LSGameStampSlot:initDatas(_index)
    self.m_index = _index
end

function LSGameStampSlot:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_stamp_slot.csb"
end

function LSGameStampSlot:initCsbNodes()
    self.m_spStamp = self:findChild("sp_stamp")
    self.m_spSlot = self:findChild("sp_slot") -- 2023
end

function LSGameStampSlot:initUI()
    LSGameStampSlot.super.initUI(self)
    self:initStamp()
end

function LSGameStampSlot:updateStamp()
    self:initStamp()
end

function LSGameStampSlot:initStamp()
    local showCur = self:getShowStampNum()
    if self.m_index <= showCur then
        self.m_spStamp:setVisible(true)
        self:initStampTexture()
    else
        self.m_spStamp:setVisible(false)
        self.m_spSlot:setVisible(false) --2023
    end
end

function LSGameStampSlot:initStampTexture()
    local stampType = self:getStampType()
    local stampPath = nil
    if stampType == LuckyStampCfg.StampType.Normal then
        stampPath = LuckyStampCfg.otherPath .. "zhang_normal.png"
    else
        stampPath = LuckyStampCfg.otherPath .. "zhang_golden.png"
    end
    if stampPath and util_IsFileExist(stampPath) then
        util_changeTexture(self.m_spStamp, stampPath)
    end
end

function LSGameStampSlot:onEnter()
    LSGameStampSlot.super.onEnter(self)
end

function LSGameStampSlot:getShowStampNum()
    if LuckyStampCfg.TEST_MODE == true then
        return 2
    end
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processData = data:getCurProcessData()
        if processData then
            return processData:getIndex()
        end
    end
    return 0
end

function LSGameStampSlot:getStampType()
    if LuckyStampCfg.TEST_MODE == true then
        return LuckyStampCfg.StampType.Normal
    end
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processData = data:getProcessDataByIndex(self.m_index)
        if processData then
            local stampType = processData:getStampType()
            return stampType
        end
    end
    return LuckyStampCfg.StampType.Normal
end

return LSGameStampSlot
