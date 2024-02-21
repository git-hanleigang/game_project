--奖池弹板
local PenguinsBoomsJackPotWinView = class("PenguinsBoomsJackPotWinView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "PenguinsBoomsPublicConfig"

local JACKPOT_INDEX = {
    grand = 1,
    mega  = 2,
    major = 3,
    minor = 4,
    mini  = 5,
}
function PenguinsBoomsJackPotWinView:initUI(params)
    local viewType = params.jackpotType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self:createCsbNode("PenguinsBooms/JackpotWinView.csb")

    --创建分享按钮
    self:createGrandShare()

    self.m_roleSpine = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsRoleSpine",{
        spineName = "PenguinsBooms_free_juese",
    })
    self:findChild("Node_roleSpine"):addChild(self.m_roleSpine)

    self.m_shineCsb = util_createAnimation("PenguinsBooms/JackpotWinView_shine.csb")
    self:findChild("Node_shine"):addChild(self.m_shineCsb)

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    self.m_node_mini = self:findChild("Node_mini")
    self.m_node_minor = self:findChild("Node_minor")
    self.m_node_mega = self:findChild("Node_mega")
    self.m_node_major = self:findChild("Node_major")
    self.m_node_grand = self:findChild("Node_grand")

    self.m_node_mini:setVisible(viewType == "mini")
    self.m_node_minor:setVisible(viewType == "minor")
    self.m_node_mega:setVisible(viewType == "mega")
    self.m_node_major:setVisible(viewType == "major")
    self.m_node_grand:setVisible(viewType == "grand")


    self.m_allowClick = false

    self:showView(self.m_winCoin)
end

--[[
    显示界面
]]
function PenguinsBoomsJackPotWinView:showView(winCoin)
    self.m_allowClick = true
    local startName = "start"
    local idleName  = "idle"
    self:runCsbAction(startName,false,function()
        -- self.m_allowClick = true
        self:runCsbAction(idleName, true)
    end)
    self.m_shineCsb:runCsbAction(idleName, true)
    self.m_roleSpine:playJackpotViewAnim()

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 613
    })
end

--[[
    金币跳动
]]
function PenguinsBoomsJackPotWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound    = PublicConfig.sound_PenguinsBooms_jackpotView_jumpCoin
    local jumpSoundEnd = PublicConfig.sound_PenguinsBooms_jackpotView_jumpCoinOver
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动120次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
    label:stopAllActions()

    if jumpSound then
        self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    end
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            self:jumpCoinsFinish()
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function PenguinsBoomsJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    if self:checkShareState() then
        return
    end

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self:jumpCoinsFinish()
        return
    end

    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end

    self:jackpotViewOver(function(  )
        self:showOver()
    end)
    
end


--[[
    关闭界面
]]
function PenguinsBoomsJackPotWinView:showOver()
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpotView_over)
    self.m_allowClick = false
    local overName = "over"
    self:runCsbAction(overName, false, function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)
end


---------------------------------------------------------------------------------------------------------
--[[
    自动分享 | 手动分享
]]
function PenguinsBoomsJackPotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function PenguinsBoomsJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoins(self.m_winCoin,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,613)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function PenguinsBoomsJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function PenguinsBoomsJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return PenguinsBoomsJackPotWinView