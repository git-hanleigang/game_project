--[[
    集卡掉卡数据
    服务器的一次掉卡数据，会存在多个来源，多个卡包
    author: 徐袁
    time: 2021-05-15 14:45:55
]]
local ParseCardDropData = require("GameModule.Card.data.ParseCardDropData")
local CardSysDropData = class("CardSysDropData")

function CardSysDropData:ctor()
    -- 掉卡信息列表
    self.m_cardInfoList = {}
    -- 掉卡来源列表
    self.m_cardSourceList = {}
    -- 当前掉落来源索引
    self.m_curSourceIndex = 1

    -- 合并卡包列表
    self.m_mergePackageSourceList = {
        ["Nado Machine"] = {"Nado Machine"},
        ["Pass"] = {"Pass"},
        ["Card Album Race Rewards"] = {"Card Album Race Rewards"},
        ["Top Up Bonus"] = {"Top Up Bonus"},
        ["Outside Cave Hammer Game"] = {"Outside Cave Hammer Game"},
        ["Crazy Wheel"] = {"Crazy Wheel"},
        ["Blast Play"] = {"Blast Play"},
    }
end

-- 解析掉落数据 --
function CardSysDropData:parseDropData(tDatas)
    tDatas = tDatas or {}
    for i = 1, #tDatas do
        -- 保存掉落数据  --
        local dropData = ParseCardDropData:create()
        dropData:parseData(tDatas[i])
        if not (dropData and dropData.source and dropData.source ~= "") then
            return
        end

        local dropInfo = clone(dropData)

        self:addDropInfo(dropInfo)
        -- self:addDropSource(dropInfo.source)
    end
end

-- 是否为空
function CardSysDropData:isEmpty()
    local count = 0
    for _key, _value in pairs(self.m_cardInfoList) do
        count = count + #_value
    end

    return not (count > 0)
end

-- 是否有掉落
function CardSysDropData:isHasDropData()
    return (#self.m_cardSourceList) > 0
end

-- 是否有掉落来源
function CardSysDropData:hasDropSource(source)
    source = source or ""
    local cardInfos = self.m_cardInfoList[source]
    if not cardInfos or #cardInfos <= 0 then
        return false
    else
        return true
    end
end

-- 添加掉落来源
function CardSysDropData:addDropSource(source)
    if not source or source == "" then
        return
    end

    for i = 1, #self.m_cardSourceList do
        if self.m_cardSourceList[i] == source then
            return
        end
    end

    table.insert(self.m_cardSourceList, source)
end

-- 添加单个卡包数据
function CardSysDropData:addDropInfo(_dropInfo)
    local _source = _dropInfo.source
    local _type = _dropInfo.type
    local _dropRound = _dropInfo:getRound()
    if _source and _source ~= "" then
        if not self.m_cardInfoList[_source] then
            self.m_cardInfoList[_source] = {}
        end
        if #self.m_cardInfoList[_source] == 0 then
            table.insert(self.m_cardInfoList[_source], _dropInfo)
            self:addDropSource(_source)
            return
        end
        if self:isMergeSource(_source) and self:isMergeDropType(_type) then
            local isMerge = false
            local dropList = self.m_cardInfoList[_source]
            for i = 1, #dropList do
                local dData = dropList[i]
                -- 相同轮次才合并
                if self:isMergeDropType(dData.type) and _dropRound == dData:getRound() then
                    isMerge = true
                    dData:mergeData(_dropInfo)
                    break
                end
            end
            if not isMerge then
                table.insert(self.m_cardInfoList[_source], _dropInfo)
                self:addDropSource(_source)
            end
        elseif self:isMergeSource(_source) and self:isMergeObsidianDropType(_type) then
            local isMerge = false
            local dropList = self.m_cardInfoList[_source]
            for i = 1, #dropList do
                local dData = dropList[i]
                if self:isMergeObsidianDropType(dData.type) then
                    isMerge = true
                    dData:mergeData(_dropInfo)
                    break
                end
            end
            if not isMerge then
                table.insert(self.m_cardInfoList[_source], _dropInfo)
                self:addDropSource(_source)
            end
        else
            table.insert(self.m_cardInfoList[_source], _dropInfo)
            self:addDropSource(_source)
        end
    end
end

function CardSysDropData:isMergeSource(_source)
    if self.m_mergePackageSourceList[_source] ~= nil then
        return true
    end
    return false
end

function CardSysDropData:isMergeDropType(_dropType)
    if _dropType == CardSysConfigs.CardDropType.normal then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.link then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.golden then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.merge then
        return true
    end
    return false
end

function CardSysDropData:isMergeObsidianDropType(_dropType)
    if _dropType == CardSysConfigs.CardDropType.obsidian_gold then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.obsidian_copper then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.obsidian_purple then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.mergeObsidian then
        return true
    end
    return false
end

-- 获得掉落来源的卡包数据
function CardSysDropData:getDropInfoBySource(dropSource)
    if #self.m_cardSourceList <= 0 then
        -- 没有掉落 或 掉落已经展示完了
        return nil
    end

    local dropSource = dropSource or ""
    local _dropInfoList = self.m_cardInfoList[dropSource]
    if _dropInfoList and #_dropInfoList > 0 then
        local _dropInfo = table.remove(self.m_cardInfoList[dropSource], 1)
        if #self.m_cardInfoList[dropSource] == 0 then
            -- 移除掉落来源
            for i = #self.m_cardSourceList, 1, -1 do
                local _source = self.m_cardSourceList[i]
                if _source == dropSource then
                    table.remove(self.m_cardSourceList, i)
                    break
                end
            end
        end

        return _dropInfo
    else
        return nil
    end
end

-- 获得下一个掉落开卡包数据
function CardSysDropData:getNextDropInfo()
    if self.m_curSourceIndex > #self.m_cardSourceList then
        -- 没有掉落 或 掉落已经展示完了
        return nil
    end

    local _source = self.m_cardSourceList[self.m_curSourceIndex]
    local _dropInfoList = self.m_cardInfoList[_source]
    if _dropInfoList and #_dropInfoList > 0 then
        local _dropInfo = table.remove(self.m_cardInfoList[_source], 1)
        if #self.m_cardInfoList[_source] == 0 then
            -- 切换下一来源索引
            -- self.m_curSourceIndex = self.m_curSourceIndex + 1
            -- 移除当前索引
            table.remove(self.m_cardSourceList, self.m_curSourceIndex)
        end

        return _dropInfo
    else
        return nil
    end
end

return CardSysDropData
