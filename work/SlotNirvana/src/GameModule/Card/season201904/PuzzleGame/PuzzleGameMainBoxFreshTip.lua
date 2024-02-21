--[[
    小游戏刷新提示
    author:{author}
    time:2020-09-04 15:53:33
]]
local BaseView = util_require("base.BaseView")
local PuzzleGameMainBoxFreshTip = class("PuzzleGameMainBoxFreshTip", BaseView)
function PuzzleGameMainBoxFreshTip:initUI()
    self:createCsbNode("CardRes/season201904/CashPuzzle/Game_main_box_Qipao.csb")

    self.m_lbTime = self:findChild("lb_time")
end

function PuzzleGameMainBoxFreshTip:onEnter()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    if data then
        local leftTime = util_getLeftTime(data.coolDown)
        leftTime = math.max(0, leftTime)
        self.m_lbTime:setString(util_count_down_str(leftTime))
    end
    
    performWithDelay(
        self,
        function()
            self:closeUI()
        end,
        3
    )
end

function PuzzleGameMainBoxFreshTip:closeUI()
    self:removeFromParent()
end

return PuzzleGameMainBoxFreshTip
