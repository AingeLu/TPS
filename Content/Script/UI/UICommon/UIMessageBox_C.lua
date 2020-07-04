require "UnLua"

local UIMessageBox_C = Class()

--function UIMessageBox_C:Initialize(Initializer)
--end

--function UIMessageBox_C:PreConstruct(IsDesignTime)
--end

function UIMessageBox_C:Construct()

    local MessageBoxContentTypeEnums = GetUIMessageBoxContentTypeEnums()
    self.MessageBoxContentType_Tb = {}

    --- CenterTextOnly
    self.MessageBoxContentType_Tb[MessageBoxContentTypeEnums.CenterTextOnly] = {}
    self.MessageBoxContentType_Tb[MessageBoxContentTypeEnums.CenterTextOnly].RootCanvas = self.MessageType1
    self.MessageBoxContentType_Tb[MessageBoxContentTypeEnums.CenterTextOnly].DescText = self.Type1DescText

    --- CenterWithIcon
    self.MessageBoxContentType_Tb[MessageBoxContentTypeEnums.CenterWithIcon] = {}
    self.MessageBoxContentType_Tb[MessageBoxContentTypeEnums.CenterWithIcon].RootCanvas = self.MessageType2
    self.MessageBoxContentType_Tb[MessageBoxContentTypeEnums.CenterWithIcon].DescText = self.Type2DescText
    self.MessageBoxContentType_Tb[MessageBoxContentTypeEnums.CenterWithIcon].IconImg = self.Type2IconImg

    --- 类型展示按钮 UI控件元素
    local MessageBoxBtnTypeEnums = GetUIMessageBoxBtnTypeEnums()
    self.MessageBoxBtnType_Tb = {}

    --- SubmitAndCancel
    self.MessageBoxBtnType_Tb[MessageBoxBtnTypeEnums.SubmitAndCancel] = {}
    self.MessageBoxBtnType_Tb[MessageBoxBtnTypeEnums.SubmitAndCancel].RootCanvas = self.BtnType1
    self.MessageBoxBtnType_Tb[MessageBoxBtnTypeEnums.SubmitAndCancel].SubmitBtn = self.SubmitBtn1
    self.MessageBoxBtnType_Tb[MessageBoxBtnTypeEnums.SubmitAndCancel].CancelBtn = self.CancelBtn1

    local submitBtn = self.MessageBoxBtnType_Tb[MessageBoxBtnTypeEnums.SubmitAndCancel].SubmitBtn
    submitBtn.OnClicked:Add(self, UIMessageBox_C.OnClicked_Submit_Btn)

    local cancelBtn = self.MessageBoxBtnType_Tb[MessageBoxBtnTypeEnums.SubmitAndCancel].CancelBtn
    cancelBtn.OnClicked:Add(self, UIMessageBox_C.OnClicked_Cancel_Btn)
end

--function UIMessageBox_C:Tick(MyGeometry, InDeltaTime)
--end


----------------------------------------------------------
--[[

    messageBoxData =
    {
        contentType ,  为 UIConfig LUIManager.UIMessageBoxContentType 中的类型
        btnType ,  为 UIConfig LUIManager.UIMessageBoxBtnType 中的类型
        titleText , 为标题
        descText , 为描述文字
        bShowClose , 控制是否显示关闭按钮
        submitCallBack
        cancelCallBack
    }


    local messageBoxData = {}
    messageBoxData.contentType = GetUIMessageBoxContentTypeEnums().CenterTextOnly
    messageBoxData.btnType = GetUIMessageBoxBtnTypeEnums().SubmitAndCancel
    messageBoxData.titleText = "标题"
    messageBoxData.descText = "内容"
    messageBoxData.bShowClose = false
    messageBoxData.submitCallBack = self.OnSubmitCallBack

    UIManager:ShowWindow("UIMessageBox" , MessageBoxData)

--]]
------------------------------------------------------------

function UIMessageBox_C:OnShowWindow(messageBoxData)

    self.MessageBoxData = messageBoxData
    if self.MessageBoxData == nil then
        return
    end

    --- MessageBox 标题
    self:SetTitle(self.MessageBoxData.titleText)
    --- MessageBox 内容
    self:SetMessageBoxContentType(self.MessageBoxData.contentType)
    --- MessageBox 文字描述 图标等
    self:SetMessageBoxContentDesc()
    --- MessageBox 展示按钮类型
    self:SetMessageBoxBtnType(self.MessageBoxData.btnType)
    --- MessageBox 关闭按钮是否显示
    self:SetCloseBtn()
end

function UIMessageBox_C:SetTitle(titleText)
    self.Title_Text:SetText(titleText)
end

function UIMessageBox_C:SetMessageBoxContentType(type)

    if type <= 0 or type > #self.MessageBoxContentType_Tb then
        return
    end

    for i = 1, #self.MessageBoxContentType_Tb do
        if self.MessageBoxContentType_Tb[i] ~= nil then
            self.MessageBoxContentType_Tb[i].RootCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end

    if self.MessageBoxContentType_Tb[type] ~= nil then
        self.MessageBoxContentType_Tb[type].RootCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
end

function UIMessageBox_C:SetMessageBoxContentDesc()
    local contentType = self.MessageBoxData.contentType

    if contentType <= 0 or contentType > #self.MessageBoxContentType_Tb then
        return
    end

    if self.MessageBoxContentType_Tb[contentType] ~= nil then

        self.MessageBoxContentType_Tb[contentType].DescText:SetText(self.MessageBoxData.descText)

        -- 特殊部分的显示
        --local MessageBoxContentTypeEnums = GetUIMessageBoxContentTypeEnums()
        --if contentType == MessageBoxContentTypeEnums.CenterWithIcon then
        --
        --elseif contentType == MessageBoxContentTypeEnums.CenterTextOnly then
        --
        --end
    end
end

function UIMessageBox_C:SetMessageBoxBtnType(btnType)

    if btnType <= 0 or btnType > #self.MessageBoxContentType_Tb then
        return
    end

    for i = 1, #self.MessageBoxContentType_Tb do
        if self.MessageBoxContentType_Tb[i] ~= nil then
            self.MessageBoxContentType_Tb[i].RootCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end

    if self.MessageBoxContentType_Tb[btnType] ~= nil then
        self.MessageBoxContentType_Tb[btnType].RootCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
end

function UIMessageBox_C:SetCloseBtn()

    if self.MessageBoxData.bShowClose == nil then
        return
    end

    if self.MessageBoxData.bShowClose then
        self.Close_Btn:SetVisibility(UE4.ESlateVisibility.Visible)
        self.CloseBtn_Img:SetVisibility(UE4.ESlateVisibility.Visible)
    else
        self.Close_Btn:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.CloseBtn_Img:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
end

-----------------------------------------
--- UI Event Callback
-----------------------------------------
function UIMessageBox_C:OnClicked_Submit_Btn()
    if self.MessageBoxData.submitCallBack ~= nil then
        if type(self.MessageBoxData.submitCallBack) == "function" then
            self.MessageBoxData.submitCallBack()
        end
    end

    LUIManager:DestroyUI("UIMessageBox")
end

function UIMessageBox_C:OnClicked_Cancel_Btn()
    if self.MessageBoxData.cancelCallBack ~= nil then
        if type(self.MessageBoxData.cancelCallBack) == "function" then
            self.MessageBoxData.cancelCallBack()
        end
    end

    LUIManager:DestroyUI("UIMessageBox")
end

return UIMessageBox_C
