--[[
    升星
]]

local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksStarUpReward = class("SidekicksStarUpReward", BaseLayer)

function SidekicksStarUpReward:initDatas(_seasonIdx, _data)
    self.m_seasonIdx = _seasonIdx
    self.m_data = _data

    self:setLandscapeCsbName(string.format("Sidekicks_%s/csd/reward/Sidekicks_Reward_Starup.csb", _seasonIdx))
    self:setExtendData("SidekicksStarUpReward")
end

function SidekicksStarUpReward:initCsbNodes()
    self.m_sp_icon_coin = self:findChild("sp_icon_coin")
    self.m_lb_coins = self:findChild("lb_coins")
end

function SidekicksStarUpReward:initView()
    self.m_coins = self.m_data:getStarUpCoins()
    
    if tonumber(self.m_coins) > 0 then
        self.m_lb_coins:setString(util_formatCoins(self.m_coins, 12))
        local uiList = {
            {node = self.m_sp_icon_coin},
            {node = self.m_lb_coins, alignX = 3}
        }
        util_alignCenter(uiList)
    end
end

function SidekicksStarUpReward:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function SidekicksStarUpReward:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_collect" then
        local flyList = {}
        local btnCollect = self:findChild("btn_collect")
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        if tonumber(self.m_coins) > 0 then
            table.insert(flyList, { cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos })
        end

        G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, function()
            if not tolua.isnull(self) then
                self:closeUI(function ()
                    gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_STAR_UP_REWARD_CLOSE)
                end)
            else
                gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_STAR_UP_REWARD_CLOSE)
            end
        end)
    end
end

return SidekicksStarUpReward