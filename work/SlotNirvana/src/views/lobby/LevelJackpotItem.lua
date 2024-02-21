local LevelJackpotItem = class("LevelJackpotItem", util_require("base.BaseView"))

function LevelJackpotItem:initUI(info)
    self.m_info = info
    self:createCsbNode("newIcons/Level_kongjian/Level_jackpot_big.csb",true)

    self:playAnim()
    self:initJackpot()
end

function LevelJackpotItem:initJackpot()
    local lbJackpotNew = self:findChild("lbJackpotNew")
    lbJackpotNew:setPositionX(lbJackpotNew:getPositionX()-7)
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

function LevelJackpotItem:playAnim()
    local Node_effect = self:findChild("Node_effect")
    local jackpotEff = util_createAnimation("newIcons/Level_kongjian/Level_jackpot_effect_big.csb")
    if jackpotEff and Node_effect then
        Node_effect:addChild(jackpotEff)
        jackpotEff:playAction("change1",true)
    end
end
return LevelJackpotItem