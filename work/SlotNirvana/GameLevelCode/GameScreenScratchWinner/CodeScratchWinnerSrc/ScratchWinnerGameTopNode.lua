local GameTopNode = util_require("views.gameviews.GameTopNode") 
local ScratchWinnerGameTopNode = class("ScratchWinnerGameTopNode", GameTopNode)
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"

-- 保存一下主棋盘对象
function ScratchWinnerGameTopNode:initUI(machine)
    self.m_machine = machine
    --数量变更
    gLobalNoticManager:addObserver(self,function(self,params)
        self:changeCoinsState()
    end,"ScratchWinnerMachine_changeBuyCount")
    ScratchWinnerGameTopNode.super.initUI(self, machine)
end
--颜色变化的检测数值适用卡片的总钱数
function ScratchWinnerGameTopNode:changeCoinsState()
    if not self.m_machine then
        return
    end
    local shopList = self.m_machine.m_shopList
    if not shopList then
        return
    end
    local shopMag = self.m_machine.m_shopMag
    if not shopMag then
        return
    end

    -- 文本状态
    local labState = true

    -- bonus时:检测金币是否满足一下张卡片花费
    local bBonus = self.m_machine:isInScratchWinnerBonusGame()
    if bBonus then
        labState = shopMag:checkRewardState()
    -- 商店时:当前金币满足购物车的花费
    else
        local buyList  = shopList:getCurBuyList()
        labState = shopMag:checkBuyState_coins(buyList)
    end

    if not labState then 
        if self.m_coinNumState == 1 then
            return
        end
        self.m_coinNumState = 1
        local count = 0
        local change = true
        self.m_coinNumStateAction =
            schedule(
            self,
            function()
                if change == true then
                    count = count + 25.5
                    if count >= 255 then
                        count = 255
                        change = false
                    end
                else
                    count = count - 25.5
                    if count <= 0 then
                        count = 0
                        change = true
                    end
                end
                self.m_coinLabel:setColor(cc.c3b(255, count, count))
            end,
            0.03
        )
    else
        if self.m_coinNumStateAction then
            self:stopAction(self.m_coinNumStateAction)
        end
        self.m_coinLabel:setColor(cc.c3b(255, 255, 255))
        self.m_coinNumState = 0
    end
end
return ScratchWinnerGameTopNode