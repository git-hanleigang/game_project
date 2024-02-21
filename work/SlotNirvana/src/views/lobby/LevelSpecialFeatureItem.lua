local LevelJackpotItem = require "views.lobby.LevelJackpotItem"
local LevelSpecialFeatureItem = class("LevelSpecialFeatureItem", LevelJackpotItem)
function LevelSpecialFeatureItem:initUI(info, icon)
    self.m_info = info
    self:createCsbNode("newIcons/Level_kongjian/Level_wanfa_big.csb",true)

    local sp_wanfa = self:findChild("sp_wanfa")
    util_changeTexture(sp_wanfa, icon)
    
    self:initJackpot()
end


function LevelSpecialFeatureItem:initJackpot()
    local lbJackpotNew = self:findChild("lbJackpotNew")
    lbJackpotNew:setPositionX(lbJackpotNew:getPositionX()-3)
    schedule(self,function ()
        local jackpotPools = globalData.jackpotRunData:getJackpotList(self.m_info.p_id)
        if jackpotPools then
            local grandText = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[1])
            local formatText = util_getFromatMoneyStr(grandText)
            lbJackpotNew:setString(formatText)
            util_scaleCoinLabGameLayerFromBgWidth(lbJackpotNew,192,1)
        end
    end,0.08)    
end


return LevelSpecialFeatureItem