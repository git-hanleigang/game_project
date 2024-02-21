--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-07-06 15:44:46
]]

local CardSpecialClanData = require("GameModule.CardSpecialClans.model.CardSpecialClanData")
local BaseGameModel = require("GameBase.BaseGameModel")
local CardSpecialClanDatas = class("CardSpecialClanDatas", BaseGameModel)

function CardSpecialClanDatas:ctor()
    self:setRefName(G_REF.CardSpecialClan)
end

function CardSpecialClanDatas:parseData(_cardClans, _magicCoins)
    -- 全部卡的数量
    self.m_totalCardNum = 0
    -- 全部拥有的卡的数量
    self.m_totalHaveCardNum = 0
    
    -- 章节数据
    self.p_specialClans = {}
    for i = 1, #_cardClans do
        -- 筛选数据
        local clanType = _cardClans[i].type
        if CardSysRuntimeMgr:isMagicClan(clanType) or CardSysRuntimeMgr:isQuestMagicClan(clanType) then
            local specialClanData = CardSpecialClanData:create()
            specialClanData:parseData(_cardClans[i])
            table.insert(self.p_specialClans, specialClanData)

            self.m_totalCardNum = self.m_totalCardNum + specialClanData:getCardNum()
            self.m_totalHaveCardNum = self.m_totalHaveCardNum + specialClanData:getHaveCardNum()
        end
    end

    -- magic全部完成的大奖
    self.p_magicCoins = tonumber(_magicCoins or "0")
end

function CardSpecialClanDatas:getSpecialClans()
    return self.p_specialClans
end

function CardSpecialClanDatas:getMagicCoins()
    return self.p_magicCoins
end

function CardSpecialClanDatas:getSpecialClanById(_clanId)
    if self.p_specialClans and #self.p_specialClans > 0 then
        for i=1,#self.p_specialClans do
            local clanData = self.p_specialClans[i]
            if clanData:getClanId() == _clanId then
                return clanData
            end
        end
    end
    return nil
end

function CardSpecialClanDatas:getSpecialClanByIndex(_index)
    _index = _index or 1 -- 兼容线上默认为第一个
    if self.p_specialClans and #self.p_specialClans > 0 then
        return self.p_specialClans[_index]
    end
    return nil
end

function CardSpecialClanDatas:getTotalHaveCardNum()
    return self.m_totalHaveCardNum
end

function CardSpecialClanDatas:getTotalCardNum()
    return self.m_totalCardNum
end

function CardSpecialClanDatas:isAlbumCompleted()
    if self.m_totalHaveCardNum == self.m_totalCardNum then
        return true
    end
    return false
end

return CardSpecialClanDatas