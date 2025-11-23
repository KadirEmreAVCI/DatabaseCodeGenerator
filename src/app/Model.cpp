#include "Model.h"

Model::Model(const Position& rPosition, const QString& sName, QObject *parent) : m_rPosition(rPosition), m_sName{sName}, QObject(parent)
{
}
int Model::GetX() const
{
    return m_rPosition.x;
}
int Model::GetY() const
{
    return m_rPosition.y;
}
QString Model::GetName() const
{
    return m_sName;
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
void Model::SetName(const QString &name)
{
    if(m_sName != name)
    {
        m_sName = name;
        emit nameChanged();
    }
}