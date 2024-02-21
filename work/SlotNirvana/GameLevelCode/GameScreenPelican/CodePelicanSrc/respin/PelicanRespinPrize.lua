---
--island
--2018年4月12日
--PelicanRespinPrize.lua
local PelicanRespinPrize = class("PelicanRespinPrize", util_require("base.BaseView"))
function PelicanRespinPrize:initUI(data)

    local resourceFilename = "Pelican_Respin_Prize.csb"
    self:createCsbNode(resourceFilename)

    -- self.baoDian = util_createAnimation("Pelican_Respin_Prize_0.csb")
    -- self:findChild("baodian"):addChild(self.baoDian,10)
    -- self.baoDian:setVisible(false)
    self.tong = util_spineCreate("Socre_Pelican_Bonus6",true,true)
    self:findChild("baodian"):addChild(self.tong,5)
    util_spinePlay(self.tong,"repeatilde2",true)
    
end
function PelicanRespinPrize:updateView(curNum,lastNum)
    if lastNum then
        self:jumpCoins({label = self:findChild("lbs_curNum"),
            startCoins = lastNum ,
            endCoins = curNum,
            duration = 18/30,
            maxWidth = 1087,

        })
    else
        if tonumber(curNum) > 0 then
            self:playCollect()
        end
        if curNum == 0 then
            self:findChild("lbs_curNum"):setString("")
        else
            self:findChild("lbs_curNum"):setString(util_formatCoins(curNum, 20))
            self:updateLabelSize({label=self:findChild("lbs_curNum"),sx=0.4,sy=0.4},1087)
        end
    end
    
    
end

function PelicanRespinPrize:changeTong(isHave)
    
    -- util_spinePlay(self.tong,"repeatstart",false)
    -- util_spineEndCallFunc(self.tong,"repeatstart",function (  )
    --     util_spinePlay(self.tong,"repeatidle",true)
    -- end)
end

function PelicanRespinPrize:fankui( )
    -- util_spinePlay(self.tong,"repeatswitch",false)
end

function PelicanRespinPrize:jiman( )
    -- util_spinePlay(self.tong,"repeatidle2",true)
end

function PelicanRespinPrize:playCollect()
    -- globalMachineController:playSound("PelicanSounds/music_Pelican_bonusCollectBuling.mp3")

end

function PelicanRespinPrize:changeTitle(type)
  
end

function PelicanRespinPrize:repeatChangBig( )
    self:runCsbAction("repeatstart",false,function (  )
        self:runCsbAction("repeatidle")
    end)
end

function PelicanRespinPrize:showFanKui( )
    -- self.baoDian:setVisible(true)
    -- self.baoDian:runCsbAction("shouji")
    
end

function PelicanRespinPrize:resetSize( )
    self:runCsbAction("repeatswitch")
end

function PelicanRespinPrize:hideView()
    self:setVisible(false)
end

--[[
    金币跳动
]]
function PelicanRespinPrize:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    -- local perFunc = params.perFunc  --每次跳动回调
    -- local endFunc = params.endFunc  --结束回调
    -- local jumpSound = "MagicianSounds/sound_Magician_jackpot_rise.mp3"
    -- local jumpSoundEnd = "MagicianSounds/sound_Magician_jackpot_rise_down.mp3"
    -- self.m_jumpSoundEnd = jumpSoundEnd

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label:stopAllActions()

    -- if jumpSound then
    --     self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    -- end
    
    self:findChild("lbs_curNum"):setString(util_formatCoins(startCoins, 20))
    self:updateLabelSize({label=self:findChild("lbs_curNum"),sx=0.4,sy=0.4},1087)
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        -- if type(perFunc) == "function" then
        --     perFunc()
        -- end

        if curCoins >= endCoins then

            curCoins = endCoins
            label:setString(util_formatCoins(curCoins,50))
            local info={label = label,sx = 0.4,sy = 0.4}
            self:updateLabelSize(info,maxWidth)

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                -- if jumpSoundEnd then
                --     gLobalSoundManager:playSound(jumpSoundEnd)
                -- end
                self.m_soundId = nil
            end

            label:stopAllActions()

            self.m_isJumpOver = true
            --结束回调
            -- if type(endFunc) == "function" then
            --     endFunc()
            -- end

        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 0.4,sy = 0.4}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end


return PelicanRespinPrize
