require "helper"
require "VisibleRect"

local LINE_SPACE = 40

local CurPos = {x = 0, y = 0}
local BeginPos = {x = 0, y = 0}

local audioEndineSupported = false
local currPlatform = cc.Application:getInstance():getTargetPlatform()
if (cc.PLATFORM_OS_WINDOWS == currPlatform or cc.PLATFORM_OS_MAC == currPlatform or cc.PLATFORM_OS_IPHONE == currPlatform or cc.PLATFORM_OS_IPAD == currPlatform or cc.PLATFORM_OS_ANDROID == currPlatform) then
    audioEndineSupported = true
end

local curSpineIndex  = 1
local tblAllSpineName = {}
local nodeSpine
local textInfo

function initArges()
    for i = runSpineStartIndexN,runSpineEndIndexN do
        table.insert(tblAllSpineName, tblAnimName[i])
    end
end

function CreateTestMenu()
    initArges()
    
    local size = cc.Director:getInstance():getWinSize()
    local layer = cc.Layer:create()
    local nodeCenter = cc.Node:create()
    layer:addChild(nodeCenter)
    nodeCenter:setPosition(cc.p(size.width/ 2, size.height/2))

    -- 图片
    local imgPath = "useBg.png"
    if cc.FileUtils:getInstance():isFileExist(imgPath) then
        local spTimp = cc.Sprite:create(imgPath)
        nodeCenter:addChild(spTimp)
    end

    local plistPath = "usePlist.plist"
    if cc.FileUtils:getInstance():isFileExist(plistPath) then
        local spTimp = cc.Sprite:create(plistPath)
        local plistNode= cc.ParticleSystemQuad:create(plistPath)
        nodeCenter:addChild(plistNode)
        plistNode:setPosition(cc.p(particleX, particleY))
        plistNode:setBlendFunc({src = gl[particleBlendSrc], dst = gl[particleBlendDst]})
    end

    -- 按钮
    nodeCenter:addChild(createBtn(false, size))
    nodeCenter:addChild(createBtn(true, size))
    -- spine
    nodeSpine = cc.Node:create()
    nodeCenter:addChild(nodeSpine)

    if runShowLine then
        local drawNode = cc.DrawNode:create()
        nodeCenter:addChild(drawNode)
        drawNode:drawLine(cc.p(0, -size.height/2),cc.p(0, size.height/2), cc.c4f(1,1,1,0.3))
        drawNode:drawLine(cc.p(-size.width/ 2, 0),cc.p(size.width/ 2, 0), cc.c4f(1,1,1,0.3))
    end

    -- 文字
    textInfo = cc.Label:createWithTTF("", "arial.ttf", 32)
    nodeCenter:addChild(textInfo)
    textInfo:setAnchorPoint(cc.p(0, 1))
    textInfo:setPosition(cc.p(-size.width/ 2 + 20, size.height/2 - 20))
    textInfo:setOpacity(150)
    runSpineAction()

    local fntPath = "font.fnt"
    if runFntText and cc.FileUtils:getInstance():isFileExist(fntPath) then
        local textFntShow = cc.Label:createWithBMFont(fntPath, runFntText)
        nodeCenter:addChild(textFntShow)
        if not string.find(runFntText, " ") then
            textInfo:setString("meiyou kongge zifu!!!!!!!")
        end
    end
    return layer
end

function runSpineAction()
    if not cc.FileUtils:getInstance():isFileExist( "spine/" .. runSpineName .. ".json") then
        return
    end
    nodeSpine:removeAllChildren()
    local spineNum = spineBornNum or 1
    for i=1,spineNum do
        local spine = sp.SkeletonAnimation:create("spine/" .. runSpineName .. ".json", "spine/" .. runSpineName .. ".atlas", 1)
        spine:setAnimation(0, tblAllSpineName[curSpineIndex], not isSinglePlay)
        nodeSpine:addChild(spine)
        spine:setScale(runScale)
        textInfo:setString(tblAllSpineName[curSpineIndex])
        if spineNum ~= 1 then
            spine:setPosition(math.random(-300,300),math.random(-300,300))
        end
    end
end

function createBtn(isRight, size)
    local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            curSpineIndex = isRight and  curSpineIndex + 1 or curSpineIndex - 1
            if curSpineIndex > #tblAllSpineName then curSpineIndex = 1 end    
            if curSpineIndex <= 0 then curSpineIndex = #tblAllSpineName end 
            runSpineAction()
        end
    end
    local button = ccui.Button:create()
    button:setTouchEnabled(true)
    button:setScale9Enabled(true)
    button:loadTextures("btn_bg.png", "btn_bg.png", "")
    button:addTouchEventListener(touchEvent)
    button:setPosition(cc.p(0, 0))
    if isRight then
        button:setAnchorPoint(cc.p(0, 0.5))
    else
        button:setAnchorPoint(cc.p(1, 0.5))
    end
    button:setContentSize(cc.size(size.width/ 2 -10, size.height-10))
    button:setOpacity(0)
    return button
end