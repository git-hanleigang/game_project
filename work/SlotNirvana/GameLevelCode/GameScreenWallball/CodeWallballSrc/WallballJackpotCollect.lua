---
--xcyy
--2018年5月23日
--WallballJackpotCollect.lua

local WallballJackpotCollect = class("WallballJackpotCollect",util_require("base.BaseView"))

local JACKPOT_NUM = 
{
    "Grand",
    "Major",
    "Minor"
}

WallballJackpotCollect.m_vecCollectNum = nil

WallballJackpotCollect.m_iConutGrand = nil
function WallballJackpotCollect:initUI()

    self:createCsbNode("Wallball_shoujitiao.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    
    for i = 1, #JACKPOT_NUM, 1 do
        local index = 1
        local key = JACKPOT_NUM[i]
        while true do
            local parent = self:findChild(key.."_"..index)
            if parent ~= nil then
                self[key..index] = util_createView("CodeWallballSrc.WallballCollectDot")
                parent:addChild(self[key..index])
            else
                break
            end
            index = index + 1
        end
        self[key.."_effect"] = util_createView("CodeWallballSrc.WallballCollectEffect", key)
        self:findChild("Node_effect"):addChild(self[key.."_effect"])
        self[key.."_effect"]:setVisible(false)
    end
    self.m_vecCollectNum = {}
end

function WallballJackpotCollect:onEnter()

end

function WallballJackpotCollect:onExit()
 
end

function WallballJackpotCollect:showCollect(jackpot)
    local nodeName = jackpot..self.m_vecCollectNum[jackpot]
    self[nodeName]:collectAnim()
    self[jackpot.."_effect"]:setVisible(true)
    self[jackpot.."_effect"]:collectAnim()
end

function WallballJackpotCollect:hideEffect()
    for i = 1, #JACKPOT_NUM, 1 do
        local key = JACKPOT_NUM[i]
        self[key.."_effect"]:setVisible(false)
    end
end

function WallballJackpotCollect:showDotIdle(vecJackpot)
    for key, value in pairs(vecJackpot) do
        for i = 1, value, 1 do
            local nodeName = key..i
            self[nodeName]:showIdle()
        end
        self.m_vecCollectNum[key] = value
    end
end

function WallballJackpotCollect:getEndPos(jackpot)
    if self.m_vecCollectNum[jackpot] == nil then
        self.m_vecCollectNum[jackpot] = 1
    else
        self.m_vecCollectNum[jackpot] = self.m_vecCollectNum[jackpot] + 1
    end
    local nodeName = jackpot.."_"..self.m_vecCollectNum[jackpot]
    local node = self:findChild(nodeName)
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return worldPos
end

function WallballJackpotCollect:resetUI(jackpot)
    local index = 1
    while true do
        if self[jackpot..index] ~= nil then
            self[jackpot..index]:setVisible(false)
        else
            break
        end
        index = index + 1
    end
end

function WallballJackpotCollect:resetJackpot()
    for i = 1, #JACKPOT_NUM, 1 do
        local key = JACKPOT_NUM[i]
        self.m_vecCollectNum[key] = 0
        self[key.."_effect"]:setVisible(false)
        self:resetUI(key)
    end
end



return WallballJackpotCollect