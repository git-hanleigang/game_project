local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")

local GoldenPigCollectGame = class("GoldenPigCollectGame",BaseGame )

local COLLECT_ROW = 4
local COLLECT_COL = 7
local REWARD_ITEM_TAG = 999

function GoldenPigCollectGame:initUI(data)
    self.m_data = data
    self.m_rewardNodeList = {}
	self.m_curClickRewardItem = nil
	self.m_currChooseRow = nil
	self.m_totalMultip = 0
    self.m_isChoose = false

	self:createCsbNode("GoldenPig/Collect.csb")

    self.m_bgSound = gLobalSoundManager:playBgMusic("GoldenPigSounds/music_GoldenPig_collect_bg.mp3")

	self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
    end)

    self:initRewardUI()

    self.m_labStartPrice = self:findChild("m_lb_coins")
    self.m_labStartPrice:setString(util_formatCoins(self.m_data.startPrice, 15))
    self:updateLabelSize({label=self.m_labStartPrice,sx=1,sy=1},316)
    self.m_labMultip = self:findChild("m_lb_num")
    self.m_labMultip:setString("")
end

function GoldenPigCollectGame:initMachine(machine)
    self.m_machine = machine
end

function GoldenPigCollectGame:onEnter()
    BaseGame.onEnter(self)
end

function GoldenPigCollectGame:onExit()
    BaseGame.onExit(self)

    if self.m_bgSound then
        gLobalSoundManager:stopAudio(self.m_bgSound)
        self.m_bgSound = nil
    end
end

--初始化奖品列表
function GoldenPigCollectGame:initRewardUI()
	self.m_rewardNodeList = {}
    self.m_currChooseRow = 1

	local rewardIndex = 1

	for i=1,COLLECT_ROW do
		self.m_rewardNodeList[i] = {}
		for j=1,COLLECT_COL do
			local data = {}
			data.index = rewardIndex
			data.row = i
			data.col = j

			rewardIndex = rewardIndex + 1

			local rewardNode = self:findChild("Node_" .. i .. "_" .. j)
			local rewardItem = util_createView("CodeGoldenPigSrc.GoldenPigCollectRewardItem",data)
			rewardItem:setClickFunc(function (  )
				self:clickItemCallFunc(rewardItem)
			end)

            rewardItem:setTag(REWARD_ITEM_TAG)
            rewardNode:addChild(rewardItem)

			table.insert(self.m_rewardNodeList[i],rewardNode)
		end
	end

    self:showCanChooseRow()
end

--当前可选行
function GoldenPigCollectGame:showCanChooseRow()
    for i,v in ipairs(self.m_rewardNodeList[self.m_currChooseRow]) do
        local rewardItem = v:getChildByTag(REWARD_ITEM_TAG)
        if rewardItem then
            rewardItem:showItemStart()
        end
    end
end

--显示当前行选中结果
function GoldenPigCollectGame:showCurrentRowChooseResult(curItem)
    if curItem:getItemRow() == self.m_currChooseRow then
        local realColumn = self.m_data.hitPositions[self.m_currChooseRow]
        --hitPositions 从0开始
        if realColumn then
            local resultData = self.m_data.cellTable[self.m_currChooseRow][realColumn + 1]
            if resultData then
                curItem:showChooseResult(resultData,function (  )
                    self:showCurrentRowOtherResult(curItem)
                end)
            end
        end
    end
end

--显示当前行其他结果
function GoldenPigCollectGame:showCurrentRowOtherResult(curItem)
    local curRowDataList = self.m_data.cellTable[self.m_currChooseRow]
    --hitPositions 从0开始
    local realChooseColumn = self.m_data.hitPositions[self.m_currChooseRow] + 1

    if curRowDataList and realChooseColumn then
        local realChooseResult = curRowDataList[realChooseColumn]
        local isAllWin = realChooseResult.type == "allwin"
        local isEnd = realChooseResult.type == "end"

        local lessResultList = clone(curRowDataList)
        table.remove(lessResultList,realChooseColumn)

        local flyNodeList = {}
        --allwin 不飞动画
        if not isAllWin and not isEnd then
            table.insert(flyNodeList,curItem:getParent())
        end

        local index = 1
        for i = 1, #self.m_rewardNodeList[self.m_currChooseRow] do
            local rewardNode = self.m_rewardNodeList[self.m_currChooseRow][i]
            local rewardItem = rewardNode:getChildByTag(REWARD_ITEM_TAG)

            if rewardItem and rewardItem:getItemIndex() ~= curItem:getItemIndex() then
                local result = lessResultList[index]
                local isLast = index == #lessResultList

                local callBackFun = function (  )
                    if isLast then
                        self:addCollectMultipleFlyEffect(flyNodeList,function (  )
                            self:updateCollectRewardInfo()
                        end)
                    end
                end

                if isAllWin then
                    --过滤其他allwin end
                    if result.type ~= "allwin" and result.type ~= "end" then
                        table.insert(flyNodeList,rewardNode)
                        rewardItem:showChooseResult(result,callBackFun)
                    else
                        rewardItem:showUnChooseResult(result,callBackFun)
                    end
                else
                    rewardItem:showUnChooseResult(result,callBackFun)
                end

                index = index + 1
            end
        end
    end
end

--奖励点击
function GoldenPigCollectGame:clickItemCallFunc(item)
	-- print("================ item index ",item:getItemIndex())

    if not self.m_isChoose then
        local rewardNode = item:getParent()
        rewardNode:setZOrder(1)
        self:showCurrentRowChooseResult(item)
        self.m_isChoose = true
    end
end

--翻倍动画
function GoldenPigCollectGame:addCollectMultipleFlyEffect(flyNodeList, callBackFun)
    if #flyNodeList > 0 then
        --sort
        table.sort(flyNodeList,function ( node1, node2 )
            local rewardItem1 = node1:getChildByTag(REWARD_ITEM_TAG)
            local rewardItem2 = node2:getChildByTag(REWARD_ITEM_TAG)

            if rewardItem1 and rewardItem2 then
                return rewardItem1:getItemIndex() < rewardItem2:getItemIndex()
            end

            return true
        end)

        self:collectMultipleFlyEffect(flyNodeList,callBackFun)
    else
        --延迟执行回调
        performWithDelay(self,function()
            if callBackFun then
                callBackFun()
            end
        end,0.5)
    end
end

function GoldenPigCollectGame:collectMultipleFlyEffect(flyNodeList, callBackFun)
    if #flyNodeList > 0 then
        local rewardNode = flyNodeList[1]
        self:collectFlyEffect(rewardNode,function (  )
            self:updateTotalMultip(rewardNode,function (  )
                if #flyNodeList > 0 then
                    table.remove(flyNodeList,1)
                    self:collectMultipleFlyEffect(flyNodeList,callBackFun)
                end
            end)
        end)
    else
        --延迟执行回调 不然最后一个倍数刚加完还没看清 就执行后续了
        performWithDelay(self,function()
            if callBackFun then
                callBackFun()
            end
        end,0.5)
    end
end

function GoldenPigCollectGame:collectFlyEffect(rewardNode, callBackFun)
    gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_collect_num.mp3")

    local worldStartPos = rewardNode:getParent():convertToWorldSpace(cc.p(rewardNode:getPosition()))
    local nodeStartPos = self:convertToNodeSpace(cc.p(worldStartPos.x,worldStartPos.y))

    local worldEndPos = self.m_labMultip:getParent():convertToWorldSpace(cc.p(self.m_labMultip:getPosition()))
    local nodeEndPos = self:convertToNodeSpace(cc.p(worldEndPos.x,worldEndPos.y))

    local particle = cc.ParticleSystemQuad:create("effect/GoldenPig_TWlizi1.plist")
    particle:setPosition(nodeStartPos)
    self:addChild(particle,999)

    local distance = ccpDistance(nodeStartPos, nodeEndPos)
    local flyTime = distance / 1000
    local actMoveTo = cc.MoveTo:create(flyTime, nodeEndPos)
    local actCallFun = cc.CallFunc:create(function (  )
        if callBackFun then
            callBackFun()
        end

        particle:removeFromParent()
    end)
    local actSeq = cc.Sequence:create(actDelay,actMoveTo,actCallFun)

    particle:runAction(actSeq)
end

--更新当前倍数
function GoldenPigCollectGame:updateTotalMultip(rewardNode, callBackFun)
    local rewardItem = rewardNode:getChildByTag(REWARD_ITEM_TAG)
    if rewardItem then
        local itemResult = rewardItem:getItemResult()
        if itemResult.type == "multi" then
            self.m_totalMultip = self.m_totalMultip + itemResult.value

            local effect, act = util_csbCreate("GoldenPig_PigjiesuanFK.csb")
            self.m_labMultip:getParent():addChild(effect)
            effect:setPosition(self.m_labMultip:getPosition())

            self.m_labMultip:setString(self.m_totalMultip)

            util_csbPlayForKey(act, "actionframe", false, function()
                if callBackFun then
                    callBackFun()
                end

                effect:removeFromParent()
            end)
        else
            if callBackFun then
                callBackFun()
            end
        end
    end
end

--更新开箱信息
function GoldenPigCollectGame:updateCollectRewardInfo()
    self.m_currChooseRow = self.m_currChooseRow + 1

    --说明还有下一行可选
    if self.m_data.hitPositions[self.m_currChooseRow] then
        self:showCanChooseRow()
        self.m_isChoose = false
    else
        if self.m_bgSound then
            gLobalSoundManager:stopAudio(self.m_bgSound)
            self.m_bgSound = nil
        end

        self:closeUI()
        self.m_machine:addCollectOverView()
    end
end

function GoldenPigCollectGame:closeUI()
    self:runCsbAction("over",false,function(  )
        self:removeFromParent()
    end)
end

return GoldenPigCollectGame