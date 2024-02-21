local GameBottomChallengePop = class("GameBottomChallengePop", util_require("base.BaseView"))

--toComplete
function GameBottomChallengePop:initUI()
    self:createCsbNode("GameNode/ChallengeBubble.csb")
    self.m_lb_diamondNum = self:findChild("lb_diamondNum")
    self.m_isPortrait = false
    self:findChild("sp_bg_shuban"):setVisible(false)
    self:findChild("sp_bg_hengban"):setVisible(true)
    if self.m_isPortrait then
        self.m_bg = self:findChild("sp_bg_shuban")
    else
        self.m_bg = self:findChild("sp_bg_hengban")
    end
    self.m_title = self:findChild("sp_complete")
    self.m_desNode = self:findChild("node_missionComplete") --普通任务提示
    self.m_limiteNode = self:findChild("node_missionDesc") --限时任务提示
    self.m_nodeLabel = self:findChild("node_label")
end

function GameBottomChallengePop:initData(_flag)
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and luckyChallengeData:isOpen() then
        if _flag == 1 or _flag == 2 then
            --当前任务队列
            self.m_limiteNode:setVisible(false)
            local task = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getCurLevelTask(self:getLevID())
            if task and #task > 0 then
                self:updateText(task)
                self.m_desNode:setVisible(true)
            end
        else
            --限时任务提示
            self.m_desNode:setVisible(false)
            self.m_limiteNode:setVisible(true)
        end
    end
end

function GameBottomChallengePop:getLevID()
    local p_id = globalData.slotRunData.machineData.p_id
    local levedata = globalData.slotRunData:getLevelInfoByName(globalData.slotRunData.machineData.p_levelName)
    if levedata then
        p_id = levedata.p_id
    end
    return p_id
end

function GameBottomChallengePop:updateText(_task)
    for i=1,5 do
        self:findChild("node"..i):setVisible(false)
    end
    for i,v in ipairs(_task) do
        local des = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getTaskDesc(v)
        local baifenbi = math.floor((v:getBaiFenBi())*100)
        if baifenbi > 100 then
            baifenbi = 100
        end
        self:findChild("node"..i):setVisible(true)
        local lb = self:findChild("lb_misd"..i)
        local lbb = self:findChild("lb_misdh"..i)
        lb:setString(des)
        local bai = "("..baifenbi.."%)"
        lbb:setString(bai)
        local list = {lb,lbb}
        self:setCenter(list)
    end
    self:updataBg(#_task,320)
end

function GameBottomChallengePop:updataBg(_num,_with)
    local hight = 100 + (_num-1)*20
    local posY1 = -10 + (hight-100)
    local dis = (_num-1)*(10+10)
    local posY2 = -35 + dis
    local width = 320
    if _with > 310 then
        width = _with + 30
    end
    
    self.m_bg:setContentSize(cc.size(width,hight))
    self.m_nodeLabel:setPositionY(posY2)
    self.m_title:setPositionY(posY1)
end

function GameBottomChallengePop:setCenter(_uilist)
    local label1 = _uilist[1]
    local label2 = _uilist[2]
    local width1 = label1:getContentSize().width
    local width2 = label2:getContentSize().width
    local pos1 = 0 - (width1 + width2)/2
    local pos2 = pos1 + width1
    label1:setPositionX(pos1)
    label2:setPositionX(pos2)
end

--创建单个元素
function GameBottomChallengePop:createElemnt(desc, index, params)
    local isNumber = false
    for i = 1, #params do
        if desc == "%s" .. i then
            isNumber = true
            --util_formatCoins(tonumber(params[i]),3)
            local numberStr = util_formatCoins(tonumber(params[i]), 3, true, nil, true)
            desc = util_strReplace(desc, "%s" .. i, numberStr)
            break
        end
    end
    desc = string.upper(desc)
    if isNumber then
        --加粗
        return {type = 1, color = cc.YELLOW, opacity = 255, str = desc, font = "Neuron", fontSize = 18, flag = 2}
    else
        return {type = 1, color = cc.WHITE, opacity = 255, str = desc, font = "Neuron", fontSize = 18, flag = 2}
    end
end

function GameBottomChallengePop:showPop(_flag)
    self.m_popShow = true
    self:setVisible(true)
    self:initData(_flag)
    local showName = "show_heng"
    if self.m_isPortrait == true then
        showName = "show_shu"
    end
    self:runCsbAction(
        showName,
        false,
        function()
        end
    )
end
-- show_heng
-- idle_heng
-- over_heng
-- show_shu
-- idle_shu
-- over_shu

function GameBottomChallengePop:hidePop()
    self.m_popShow = false
    local showName = "over_heng"
    if self.m_isPortrait == true then
        showName = "over_shu"
    end
    self:runCsbAction(
        showName,
        false,
        function()
            self:setVisible(false)
        end
    )
end

function GameBottomChallengePop:clickFunc(sender)
    local senderName = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):showMainLayer()
end

function GameBottomChallengePop:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            self:removeFromParent()
        end
    )
end

return GameBottomChallengePop
