#include "Model.h"

Model::Model(const Position& rPosition, QObject *parent) : m_rPosition(rPosition), QObject(parent)
{
}
void Model::ChangePosition(int x, int y)
{
    if(m_rPosition.x != x || m_rPosition.y != y)
    {
        m_rPosition.x = x;
        m_rPosition.y = y;
        emit positionChanged();
    }
}
int Model::GetX() const
{
    return m_rPosition.x;
}
int Model::GetY() const
{
    return m_rPosition.y;
}