#include "UICommandBus.h"

UiCommandBus& UiCommandBus::GetInstance()
{
    static UiCommandBus instance;
    return instance;
}
UiCommandBus::UiCommandBus(QObject* parent)
    : QObject(parent)
{
}