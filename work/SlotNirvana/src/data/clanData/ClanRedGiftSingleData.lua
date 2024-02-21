--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-07 15:40:31
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-07 15:42:18
FilePath: /SlotNirvana/src/data/clanData/ClanRedGiftSingleData.lua
Description: 公会 红包 礼物信息
--]]
local ClanRedGiftSingleData = class("ClanRedGiftSingleData")

-- message ClanRedPackage {
--     optional string key = 1;//key
--     optional string keyId = 2;//keyId
--     optional string price = 3;//价格
--     optional int32 minMember = 4;//最小分奖人数
--     optional int32 maxMember = 5;//最大分奖人数
--   }
function ClanRedGiftSingleData:ctor(_idx)
    self.m_idx = _idx
    self.m_key = "" -- key
    self.m_keyId = "" -- keyId
    self.m_price = 0 -- 价格
end

function ClanRedGiftSingleData:parseData(_data)
    self.m_key = _data.key or "" -- key
    self.m_keyId = _data.keyId or "" -- keyId
    self.m_price = tonumber(_data.price) or 0 -- 价格
end

function ClanRedGiftSingleData:getKey()
    return self.m_key
end

function ClanRedGiftSingleData:getKeyId()
    return self.m_keyId
end

function ClanRedGiftSingleData:getPrice()
    return self.m_price
end

function ClanRedGiftSingleData:getIdx()
    return self.m_idx
end

return ClanRedGiftSingleData