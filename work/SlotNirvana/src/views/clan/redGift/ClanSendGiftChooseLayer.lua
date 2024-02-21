--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-01-11 16:34:58
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-02 20:23:34
FilePath: /SlotNirvana/src/views/clan/redGift/ClanSendGiftChooseLayer.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-07 14:42:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-07 16:02:22
FilePath: /SlotNirvana/src/views/clan/redGift/ClanSendGiftChooseLayer.lua
Description: 公会红包 礼物选择界面
--]]
local ClanSendGiftChooseLayer = class("ClanSendGiftChooseLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanSendGiftChooseLayer:initDatas()
    local clanData = ClanManager:getClanData() 
    self.m_teamRedGiftList = clanData:getRedGiftList()

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/Gift/Gift_choose_gift_layer.csb")
    self:setExtendData("ClanSendGiftChooseLayer")
end

function ClanSendGiftChooseLayer:initView()
    self:initPhaseUI()

    self:runCsbAction("idle", true)
end

-- 初始化档位信息
function ClanSendGiftChooseLayer:initPhaseUI()
    -- 档位 价格
    for i=1, 3 do
        local data = self.m_teamRedGiftList[i]
        local lbPrice = self:findChild("lb_coin_" .. i)
        local price = data and data:getPrice() or 0
        if price == 0 then
            lbPrice:setString("")
        else
            lbPrice:setString("$"..price)
        end
    end
end

function ClanSendGiftChooseLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_rule" then
        -- 查看规则面板
        ClanManager:popRedGiftRuleLayer()
    elseif name == "btn_close" then
        self:closeUI()
    elseif name == "btn_pick1" then
        self:closeUI(function()
            ClanManager:popGiftChooseMemberLayer(self.m_teamRedGiftList[1])
        end)
    elseif name == "btn_pick2" then
        self:closeUI(function()
            ClanManager:popGiftChooseMemberLayer(self.m_teamRedGiftList[2])
        end)
    elseif name == "btn_pick3" then
        self:closeUI(function()
            ClanManager:popGiftChooseMemberLayer(self.m_teamRedGiftList[3])
        end)
    end
end

function ClanSendGiftChooseLayer:closeUI(_cb)
    self:runCsbAction("stop_idle", false)

    -- 隐藏粒子
    if self.hidePartiicles then
        self:hidePartiicles()
    end

    ClanSendGiftChooseLayer.super.closeUI(self, _cb)
end

return ClanSendGiftChooseLayer