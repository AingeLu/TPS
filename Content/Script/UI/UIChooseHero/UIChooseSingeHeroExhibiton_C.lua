require "UnLua"

local UIChooseSingeHeroExhibiton_C = Class()

--function UIChooseSingeHeroExhibiton_C:Initialize(Initializer)
--end

--function UIChooseSingeHeroExhibiton_C:PreConstruct(IsDesignTime)
--end

function UIChooseSingeHeroExhibiton_C:Construct()
    self.enableRotation = true

    self.bClickDown = false
    self.modelRotationValue = 0
    self.currModelActor = nil
end

function UIChooseSingeHeroExhibiton_C:Destruct()
    print("UIChooseSingeHeroExhibiton_C:Destruct ...")
end

--function UIChooseSingeHeroExhibiton_C:Tick(MyGeometry, InDeltaTime)
--end

function UIChooseSingeHeroExhibiton_C:OnMouseButtonDown(MyGeometry , MouseEvent)
    print("UIChooseSingeHeroExhibiton_C:OnMouseButtonDown in Lua .")
    local  fEventReply = self.Overridden.OnMouseButtonDown(self , MyGeometry , MouseEvent )

    if not self.enableRotation then
        return
    end

    local pos = MouseEvent:GetScreenSpacePosition()

    self.bClickDown = true

    local LocalCoord = MyGeometry:AbsoluteToLocal(pos);

    self.LastPos = LocalCoord

    return fEventReply
    --local pos = UE4.FVector()
    --
    --local bSuccess = UE4.UMGLuaUtils.UMG_GetFPointEventScreenSpacePosition(MouseEvent , pos)
    --
    --if not bSuccess then
    --    print("OnMouseButtonDownEvent GetFPointEventScreenSpacePosition Failed .")
    --    return
    --end
    --
    --local LocalCoord = InGeometry:AbsoluteToLocal(pos);
    --
    --self.LastPos = LocalCoord
    --
    --print("OnMouseButtonDownEvent ... self.bClickDown = " , self.bClickDown)
end

function UIChooseSingeHeroExhibiton_C:OnMouseMove(MyGeometry , MouseEvent)

    local  fEventReply = self.Overridden.OnMouseMove(self , MyGeometry , MouseEvent )

    if not self.enableRotation then
        return
    end

    if self.bClickDown then

        --print("UIChooseSingeHeroExhibiton_C:OnMouseMove in Lua .")

        local pos = MouseEvent:GetScreenSpacePosition()

        local LocalCoord = MyGeometry:AbsoluteToLocal(pos);

        if self.LastPos == nil then
            return
        end

        local offset = LocalCoord - self.LastPos

        local dir = offset.X * -1 ;

        --print("dir = " , dir)
        self.modelRotationValue = dir

        local fRotator = UE4.FRotator(0 , self.modelRotationValue , 0)

        self:SetCurrModelRotation(fRotator)
    end

    return fEventReply
end

function UIChooseSingeHeroExhibiton_C:OnMouseButtonUp(MyGeometry , MouseEvent)

    local  fEventReply = self.Overridden.OnMouseButtonUp(self , MyGeometry , MouseEvent)

    if not self.enableRotation then
        return
    end

    self.bClickDown = false

    return fEventReply
end

function UIChooseSingeHeroExhibiton_C:OnMouseLeave(MouseEvent)

    self.Overridden.OnMouseLeave(self , MouseEvent )

    if not self.enableRotation then
        return
    end

    self.bClickDown = false
end

function UIChooseSingeHeroExhibiton_C:SetCurrModelRotation(newRotation)
    if self.currModelActor ~= nil then

        local h = UE4.FHitResult()
        local ok , h = self.currModelActor.DisplayMesh:K2_SetRelativeRotation(newRotation  ,true , h , true)

    else
        print("self.currModelActor is nil .")
    end
end


--function UIChooseSingeHeroExhibiton_C:OnShowWindow()
--end


function UIChooseSingeHeroExhibiton_C:SetSelectedModel(selectedModelActor)

    if selectedModelActor == nil then
        print("UIChooseHeroExhibition:SetCurrModel selectedModelActor is nil . posIndex = " , self.posIndex)
        return
    end

    self.currModelActor = selectedModelActor
end

function UIChooseSingeHeroExhibiton_C:SetEnableRotation(bEnable)
    self.enableRotation = bEnable
end


return UIChooseSingeHeroExhibiton_C
