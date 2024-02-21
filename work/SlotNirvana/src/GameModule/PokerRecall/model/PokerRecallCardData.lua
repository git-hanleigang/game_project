--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-12-15 14:43:01
    path:src/GameModule/PokerRecall/model/PokerRecallCardData.lua
    describe:牌数据
]]
--[[
    message PokerRecall {
    optional int32 color = 1; //牌的花色0-3
    optional int32 card = 2; //牌的值1-13
    optional bool flag = 3; //牌的状态：已翻开，未翻开
    }
]]
local PokerRecallCardData = class("PokerRecallCardData")

function PokerRecallCardData:ctor()
    self.m_intColor = 0
    self.m_intCard = 1
    self.m_boolFlag = false
end

function PokerRecallCardData:parseData(_data)
    self.m_intCard = _data.card
    self.m_intColor = _data.color
    self.m_boolFlag = _data.flag
end

function PokerRecallCardData:getCardColor()
    return self.m_intColor
end

function PokerRecallCardData:getCardValue()
    return self.m_intCard
end

function PokerRecallCardData:getCardStatus()
    return self.m_boolFlag
end

return PokerRecallCardData
