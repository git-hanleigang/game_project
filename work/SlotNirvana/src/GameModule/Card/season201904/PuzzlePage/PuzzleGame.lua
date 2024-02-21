--[[
    拼图 - 小游戏logo
]]
local BaseView = util_require("base.BaseView")
local PuzzleGame = class("PuzzleGame", BaseView)

function PuzzleGame:initUI()
    local _width = 350
    local _height = 600
    self.m_rootNode = cc.Node:create()
    self.m_rect = cc.rect(-_width / 2, -_height / 2, _width, _height)
    self.m_clipRect = cc.ClippingRectangleNode:create(self.m_rect)
    self.m_clipRect:setClippingEnabled(true)
    self:addChild(self.m_clipRect)
    self.m_clipRect:addChild(self.m_rootNode)

    self.m_itemDis = 40

    self:createSpine()
end

function PuzzleGame:updateUI(pageIndex)
end

function PuzzleGame:createSpine()
    -- local _data = CardSysRuntimeMgr:getPuzzleDataByIndex(pageIndex)
    -- if not _data then
    --     return
    -- end
    local _datas = CardSysRuntimeMgr:getPuzzleGameData()
    if _datas and _datas.puzzle then
        for i = 1, #_datas.puzzle do
            local _data = _datas.puzzle[i]
            local _spineFinger = util_spineCreate("CardRes/season201904/CashPuzzle/spine/MrCash_juese_1", true, true, 1)
            self.m_rootNode:addChild(_spineFinger)
            _spineFinger:setPosition(cc.p((i - 1) * (self.m_rect.width + self.m_itemDis), 0))

            local type = _data.type
            if type then
                if type == "NORMAL" then
                    util_spinePlay(_spineFinger, "idleframe4", true)
                elseif type == "GOLDEN" then
                    util_spinePlay(_spineFinger, "idleframe3", true)
                elseif type == "NADO" then
                    util_spinePlay(_spineFinger, "idleframe2", true)
                end
            end
        end
    end
end

-- 更新页签坐标
function PuzzleGame:updatePageItemPos(offsetXper)
    local nowX = self.m_rootNode:getPositionX()
    local offsetX = offsetXper * (self.m_rect.width)
    self.m_rootNode:setPositionX(nowX + offsetX)
end

function PuzzleGame:moveAct(desIdx, callbackFunc)
    local endPosX = (1 - desIdx) * (self.m_rect.width + self.m_itemDis)
    local moveAction = cc.MoveTo:create(0.2, cc.p(endPosX, 0))
    local callfunc =
        cc.CallFunc:create(
        function()
            if callbackFunc then
                callbackFunc()
            end
        end
    )
    local seq = cc.Sequence:create(moveAction, callfunc)
    self.m_rootNode:runAction(seq)
end

-- 取消移动回弹
function PuzzleGame:moveBackAct(offsetXper, callbackFunc)
    local nowX = self.m_rootNode:getPositionX()
    local offsetX = offsetXper * self.m_rect.width
    local moveAction = cc.MoveTo:create(0.2, cc.p(nowX + offsetX, 0))
    local callfunc =
        cc.CallFunc:create(
        function()
            if callbackFunc then
                callbackFunc()
            end
        end
    )
    local seq = cc.Sequence:create(moveAction, callfunc)

    self.m_rootNode:runAction(seq)
end

function PuzzleGame:clickFunc(sender)
    local name = sender:getName()
end

return PuzzleGame
