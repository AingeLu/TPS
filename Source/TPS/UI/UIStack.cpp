// Fill out your copyright notice in the Description page of Project Settings.


#include "UIStack.h"

void FUINode::RemoveChild(const FUINode& uiNode)
{
    if (Children.Num() <= 0)
    {
        return;
    }

    Children.Remove(uiNode);
}

void FUINode::RemoveAllChildren()
{
    if (Children.Num() <= 0)
    {
        return;
    }

    for (FUINode& child : Children)
    {
        child.RemoveFromParent();
    }
}

void FUINode::RemoveFromParent()
{
    if (Parent)
    {
        Parent->RemoveChild(*this);
    }
}


FUIStack::FUIStack()
{
}

FUIStack::~FUIStack()
{
}

void FUIStack::PushUI(EUINames name, const FUIInfo uiInfo)
{
    switch (uiInfo.Mode)
    {
    case EUIMode::MODE_MAIN:
    {
        UINodes.Add(FUINode(name, uiInfo));
    }
    break;
    case EUIMode::MODE_TIPS:
    {
        FUINode topNode = UINodes.Top();
        topNode.AddChild(FUINode(name, uiInfo, &topNode));
    }
    break;
    default:
        break;
    }
}

void FUIStack::PopUI(EUINames name, const FUIInfo uiInfo)
{
    FUINode uiNode;
    if (FindUI(name, uiNode))
    {
        switch (uiInfo.Mode)
        {
        case EUIMode::MODE_MAIN:
            UINodes.Remove(uiNode);
            break;
        case EUIMode::MODE_TIPS:
            uiNode.RemoveFromParent();
            break;
        default:
            break;
        }
    }
}

bool FUIStack::FindUI(EUINames name, FUINode& outNode)
{
    for (FUINode& uiNode : UINodes)
    {
        if (uiNode.GetName() == name)
        {
            outNode = uiNode;
            return true;
        }
        else
        {
            for (FUINode& childUINode : uiNode.GetChildren())
            {
                if (childUINode.GetName() == name)
                {
                    outNode = childUINode;
                    return true;
                }
            }
        }
    }

    return false;
}