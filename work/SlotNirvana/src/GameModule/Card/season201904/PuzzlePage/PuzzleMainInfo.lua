--[[
    红钻石不足提示
    author:{author}
    time:2020-09-04 15:53:33
]]
local BaseView = util_require("base.BaseView")
local PuzzleMainInfo = class("PuzzleMainInfo", BaseView)
function PuzzleMainInfo:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end    
    self:createCsbNode(CardResConfig.PuzzleGameMainInofRes, isAutoScale)

    self.m_start = true
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_start = false
            self:runCsbAction("idle", false)
        end
    )
end

function PuzzleMainInfo:onEnter()

end


function PuzzleMainInfo:canClick()
    if self.m_start then
        return false         
    end
    if self.m_closed then
        return false         
    end
    return true
end

function PuzzleMainInfo:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return 
    end
    if name == "btn_close" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:closeUI()
    end
end

function PuzzleMainInfo:closeUI()
    if self.m_closed then
        return         
    end
    self.m_closed = true

    self:runCsbAction(
        "over",
        false,
        function()
            self:removeFromParent()
        end
    )
end

return PuzzleMainInfo
