--金币滚动节点
local QuestNewTopCoinsShowNode = class("QuestNewTopCoinsShowNode", util_require("base.BaseView"))

QuestNewTopCoinsShowNode.NoneRank = 360

local res_suffix = {"minor.csb","major.csb","grand.csb"}

function QuestNewTopCoinsShowNode:initDatas(data)
    -- 1 minor  2 major  3 grand
    if data and data.type then
        self.m_type = data.type
    else
        self.m_type = 1
    end
end
function QuestNewTopCoinsShowNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewTopCoinsShowNode .. res_suffix[self.m_type] 
end

function QuestNewTopCoinsShowNode:initCsbNodes()
    self.m_lb_Name = self:findChild("lb_NAME") 
    self.m_lb_Coin = self:findChild("lb_shuzi") 
end

function QuestNewTopCoinsShowNode:updateCoins()
    local coinsNum,isName = G_GetMgr(ACTIVITY_REF.QuestNew):getRuningGoldByType(self.m_type)
    if isName then
        self.m_lb_Coin:setString("" .. coinsNum)
    else
        self.m_lb_Coin:setString(util_getFromatMoneyStr(coinsNum))
    end
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_Coin, 220, 1)
end

function QuestNewTopCoinsShowNode:afterSomebodyGainCoins()
    local gainCoinsName = G_GetMgr(ACTIVITY_REF.QuestNew):getGianCoinsNameByType(self.m_type)
    self.m_lb_Name:setString(""..gainCoinsName)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_Name, 220, 1)

    --执行动画
    self:doChangeToNameState(function ()
        
    end)
end

function QuestNewTopCoinsShowNode:doChangeToNameState(callBack)
    self:runCsbAction("name", false,function ()
        self:runCsbAction("winner", false,function ()
            self:runCsbAction("jackpot", false,function ()
                if callBack then
                    callBack()
                end
            end)
        end)
    end)
end

return QuestNewTopCoinsShowNode
