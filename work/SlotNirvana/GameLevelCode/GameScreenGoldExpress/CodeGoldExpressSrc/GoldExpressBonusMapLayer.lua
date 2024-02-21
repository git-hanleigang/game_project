local GoldExpressBonusMapLayer = class("GoldExpressBonusMapLayer", util_require("base.BaseView"))
-- 构造函数
local VEC_BIG_LEVEL_ID = {4, 8, 13, 19}
function GoldExpressBonusMapLayer:initUI(data, pos)
    local resourceFilename = "Bonus_GoldExpress_Map2.csb"
    self:createCsbNode(resourceFilename)
    self.m_nodePanda = self.m_csbOwner["panda"]
    self.m_panda = util_createView("CodeGoldExpressSrc.GoldExpressBonusMapPanda")
    self.m_nodePanda:addChild(self.m_panda)

    self.m_vecNodeLevel = {}
    for i = 1, #data, 1 do
        local info = data[i]
        local itemFile = nil
        local item = nil
        local BigLevelInfo = nil
        if info.type == "BIG" then
            itemFile = "CodeGoldExpressSrc.GoldExpressBonusMapBigLevel"
            BigLevelInfo = {}
            BigLevelInfo.info = info
            BigLevelInfo.currLevel = pos
            BigLevelInfo.selfPos = i
        else
            itemFile = "CodeGoldExpressSrc.GoldExpressBonusMapItem"
        end
        if i == 3 or i == 7 or i == 12 or i == 18 then  -- 大关前面的关卡
            item = util_createView(itemFile, true)
        else
            item = util_createView(itemFile, BigLevelInfo)
        end

        self.m_vecNodeLevel[#self.m_vecNodeLevel + 1] = item
        self:findChild("Node_"..i):addChild(item)
        if info.type == "BIG" then
            item:setPositionY(item:getPositionY()+40)
        end
        if i <= pos then
            item:completed()
        end
    end
    local node = self:findChild("Node_"..pos)
    self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY() - 30)

end

function GoldExpressBonusMapLayer:getLevelPosX(pos)
    return self:findChild("Node_"..pos):getPositionX()
end

function GoldExpressBonusMapLayer:pandaMove(callBack, bonusData, pos)
    local info = nil
    local bigLevel = nil
    for i = 1, 4, 1 do
        if pos < VEC_BIG_LEVEL_ID[i] then
            info = bonusData[VEC_BIG_LEVEL_ID[i]]
            bigLevel = self.m_vecNodeLevel[VEC_BIG_LEVEL_ID[i]]
            break
        end
    end
    if bonusData[pos].type == "BIG" then
        self.m_vecNodeLevel[pos]:click(function ()
            local node = self:findChild("Node_"..pos)
            -- local jump = cc.JumpTo:create(0.5, cc.p(node:getPositionX(), node:getPositionY() - 30), 60, 1)

            local moveTo =cc.MoveTo:create(1,cc.p(node:getPositionX(), node:getPositionY() - 30))
            self.m_panda:runCsbAction("actionframe",false,function(  )
                self.m_panda:runCsbAction("idle1")
            end)
            gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_levelcomplete.mp3",false)
            self.m_nodePanda:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(function()
                -- self.m_panda:runCsbAction("idle1")
                if callBack ~= nil then
                    performWithDelay(self, function()
                        callBack()
                    end, 1)
                end
            end)))
        end)
    else
        local node = self:findChild("Node_"..pos)
        local moveTo =cc.MoveTo:create(1,cc.p(node:getPositionX(), node:getPositionY() - 30))
        self.m_panda:runCsbAction("actionframe",false,function(  )
            self.m_panda:runCsbAction("idle1")
        end)

        gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_levelcomplete.mp3",false)

        -- local jump = cc.JumpTo:create(0.5, cc.p(node:getPositionX(), node:getPositionY() - 30), 60, 1)
        self.m_nodePanda:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(function()
            -- self.m_vecNodeLevel[pos]:showParticle()
            self.m_vecNodeLevel[pos]:click(function()
                if callBack ~= nil then
                    if bigLevel ~= nil then
                        bigLevel:updateExtraGame(info, pos, callBack)
                    else
                        performWithDelay(self, function()
                            callBack()
                        end, 1)
                    end
                end
            end)

        end)))
    end
end

function GoldExpressBonusMapLayer:mapReset()
    for i = 1, #self.m_vecNodeLevel, 1 do
        local item = self.m_vecNodeLevel[i]
        if item.m_baseFilePath == "Bonus_GoldExpress_daguan.csb" then
            item:levelReset()
        else
            item:idle()
        end
    end
    local node = self:findChild("Node_0")
    self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY() - 30)
end

function GoldExpressBonusMapLayer:onEnter()

end

function GoldExpressBonusMapLayer:onExit()

end


return GoldExpressBonusMapLayer